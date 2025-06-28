#!/bin/bash

# Deployment script for Next.js Medusa Storefront on Google Cloud
# Usage: ./deploy.sh [environment] [action]
# Environment: dev, staging, production
# Action: plan, apply, destroy

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[DEPLOY]${NC} $1"
}

# Usage information
usage() {
    echo "Usage: $0 [environment] [action]"
    echo "Environment: dev, staging, production (default: dev)"
    echo "Action: plan, apply, destroy (default: plan)"
    echo
    echo "Examples:"
    echo "  $0 dev plan          # Plan deployment for dev environment"
    echo "  $0 staging apply     # Apply deployment for staging environment"
    echo "  $0 production plan   # Plan deployment for production environment"
    exit 1
}

# Parse command line arguments
ENVIRONMENT=${1:-dev}
ACTION=${2:-plan}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|production)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    usage
fi

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    print_error "Invalid action: $ACTION"
    usage
fi

print_header "Deploying Next.js Medusa Storefront - Environment: $ENVIRONMENT, Action: $ACTION"

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    command -v gcloud >/dev/null 2>&1 || { print_error "gcloud CLI is required"; exit 1; }
    command -v terraform >/dev/null 2>&1 || { print_error "Terraform is required"; exit 1; }
    command -v docker >/dev/null 2>&1 || { print_error "Docker is required"; exit 1; }
    
    # Check if authenticated with gcloud
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "Not authenticated with gcloud. Run: gcloud auth login"
        exit 1
    fi
    
    print_status "Prerequisites check passed!"
}

# Set up authentication
setup_auth() {
    print_status "Setting up authentication..."
    
    # Set up Application Default Credentials
    if [ -f "terraform-sa-key.json" ]; then
        export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/terraform-sa-key.json"
        print_status "Using service account key for authentication"
    else
        print_warning "Service account key not found, using gcloud authentication"
        gcloud auth application-default login
    fi
}

# Build and push Docker image
build_and_push_image() {
    if [[ "$ACTION" == "apply" ]]; then
        print_status "Building and pushing Docker image..."
        
        PROJECT_ID=$(gcloud config get-value project)
        IMAGE_NAME="gcr.io/$PROJECT_ID/nextjs-storefront"
        IMAGE_TAG="${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S)"
        
        # Build image
        print_status "Building Docker image: $IMAGE_NAME:$IMAGE_TAG"
        docker build -f infra/docker/Dockerfile -t "$IMAGE_NAME:$IMAGE_TAG" -t "$IMAGE_NAME:latest" .
        
        # Configure Docker for GCR
        gcloud auth configure-docker --quiet
        
        # Push image
        print_status "Pushing image to Google Container Registry..."
        docker push "$IMAGE_NAME:$IMAGE_TAG"
        docker push "$IMAGE_NAME:latest"
        
        print_status "Image pushed successfully: $IMAGE_NAME:$IMAGE_TAG"
        
        # Export image tag for Terraform
        export TF_VAR_image_tag="$IMAGE_TAG"
    fi
}

# Run Terraform
run_terraform() {
    print_status "Running Terraform $ACTION..."
    
    cd infra/terraform
    
    # Select or create workspace
    if ! terraform workspace list | grep -q "$ENVIRONMENT"; then
        terraform workspace new "$ENVIRONMENT"
    else
        terraform workspace select "$ENVIRONMENT"
    fi
    
    # Set up Terraform variables
    TFVARS_FILE="environments/$ENVIRONMENT/terraform.tfvars"
    SECRETS_FILE="environments/$ENVIRONMENT/secrets.tfvars"
    
    # Check if required files exist
    if [ ! -f "$TFVARS_FILE" ]; then
        print_error "Terraform variables file not found: $TFVARS_FILE"
        exit 1
    fi
    
    if [ ! -f "$SECRETS_FILE" ]; then
        print_error "Secrets file not found: $SECRETS_FILE"
        print_error "Please create and populate: $SECRETS_FILE"
        exit 1
    fi
    
    # Common Terraform arguments
    TF_ARGS="-var-file=$TFVARS_FILE -var-file=$SECRETS_FILE"
    
    case $ACTION in
        plan)
            print_status "Running Terraform plan..."
            terraform plan $TF_ARGS
            ;;
        apply)
            print_status "Running Terraform apply..."
            if [[ "$ENVIRONMENT" == "production" ]]; then
                print_warning "You are about to deploy to PRODUCTION!"
                echo "Type 'yes' to continue:"
                read -r confirmation
                if [[ "$confirmation" != "yes" ]]; then
                    print_error "Deployment cancelled"
                    exit 1
                fi
            fi
            terraform apply $TF_ARGS -auto-approve
            
            # Show outputs
            print_status "Deployment completed! Here are the outputs:"
            terraform output
            ;;
        destroy)
            print_warning "You are about to DESTROY infrastructure for $ENVIRONMENT!"
            echo "Type 'destroy' to continue:"
            read -r confirmation
            if [[ "$confirmation" != "destroy" ]]; then
                print_error "Destruction cancelled"
                exit 1
            fi
            terraform destroy $TF_ARGS -auto-approve
            ;;
    esac
    
    cd ../..
}

# Health check
health_check() {
    if [[ "$ACTION" == "apply" ]]; then
        print_status "Performing health check..."
        
        # Get the Cloud Run URL from Terraform output
        cd infra/terraform
        URL=$(terraform output -raw cloud_run_url 2>/dev/null || echo "")
        cd ../..
        
        if [ -n "$URL" ]; then
            print_status "Application URL: $URL"
            
            # Wait for service to be ready
            print_status "Waiting for service to be ready..."
            sleep 30
            
            # Simple health check
            if curl -f "$URL/api/health" >/dev/null 2>&1; then
                print_status "Health check passed! Application is running."
            else
                print_warning "Health check failed, but deployment may still be successful."
                print_warning "Check the Cloud Run logs for more details."
            fi
        else
            print_warning "Could not retrieve application URL"
        fi
    fi
}

# Cleanup function
cleanup() {
    print_status "Cleaning up temporary files..."
    
    # Remove temporary Docker images
    if [[ "$ACTION" == "apply" ]]; then
        docker image prune -f --filter="label=stage=builder" >/dev/null 2>&1 || true
    fi
}

# Main deployment function
main() {
    print_header "Starting deployment process..."
    
    # Set up error handling
    trap cleanup EXIT
    
    check_prerequisites
    setup_auth
    build_and_push_image
    run_terraform
    health_check
    
    print_status "Deployment process completed successfully!"
    
    if [[ "$ACTION" == "apply" ]]; then
        echo
        print_status "🎉 Your Next.js Medusa Storefront is now deployed!"
        echo
        print_status "Next steps:"
        echo "1. Configure your domain (if using custom domain)"
        echo "2. Set up monitoring and alerting"
        echo "3. Configure CI/CD pipeline"
        echo "4. Test the application thoroughly"
    fi
}

# Run main function
main "$@"