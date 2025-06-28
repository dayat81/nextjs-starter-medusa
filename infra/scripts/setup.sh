#!/bin/bash

# Setup script for Google Cloud deployment
# This script initializes the GCP project and sets up the required services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    command -v gcloud >/dev/null 2>&1 || { print_error "gcloud CLI is required but not installed. Visit: https://cloud.google.com/sdk/docs/install"; exit 1; }
    command -v terraform >/dev/null 2>&1 || { print_error "Terraform is required but not installed. Visit: https://learn.hashicorp.com/tutorials/terraform/install-cli"; exit 1; }
    command -v docker >/dev/null 2>&1 || { print_error "Docker is required but not installed. Visit: https://docs.docker.com/get-docker/"; exit 1; }
    
    print_status "All prerequisites are installed!"
}

# Get project configuration
get_project_config() {
    print_status "Setting up project configuration..."
    
    # Get current project
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
    
    if [ -z "$CURRENT_PROJECT" ]; then
        echo "Enter your GCP Project ID:"
        read -r PROJECT_ID
        gcloud config set project "$PROJECT_ID"
    else
        echo "Current project: $CURRENT_PROJECT"
        echo "Use this project? (y/n)"
        read -r USE_CURRENT
        if [ "$USE_CURRENT" != "y" ]; then
            echo "Enter your GCP Project ID:"
            read -r PROJECT_ID
            gcloud config set project "$PROJECT_ID"
        else
            PROJECT_ID=$CURRENT_PROJECT
        fi
    fi
    
    # Get region
    echo "Enter your preferred region (default: us-central1):"
    read -r REGION
    REGION=${REGION:-us-central1}
    
    # Get environment
    echo "Enter environment (dev/staging/production, default: dev):"
    read -r ENVIRONMENT
    ENVIRONMENT=${ENVIRONMENT:-dev}
    
    export PROJECT_ID REGION ENVIRONMENT
}

# Enable required APIs
enable_apis() {
    print_status "Enabling required Google Cloud APIs..."
    
    apis=(
        "run.googleapis.com"
        "sql-component.googleapis.com"
        "sqladmin.googleapis.com"
        "storage.googleapis.com"
        "cloudbuild.googleapis.com"
        "compute.googleapis.com"
        "servicenetworking.googleapis.com"
        "secretmanager.googleapis.com"
        "monitoring.googleapis.com"
        "logging.googleapis.com"
    )
    
    for api in "${apis[@]}"; do
        print_status "Enabling $api..."
        gcloud services enable "$api" --project="$PROJECT_ID"
    done
    
    print_status "All APIs enabled successfully!"
}

# Create Terraform state bucket
create_terraform_state_bucket() {
    print_status "Creating Terraform state bucket..."
    
    BUCKET_NAME="${PROJECT_ID}-terraform-state"
    
    # Check if bucket already exists
    if gsutil ls -b gs://"$BUCKET_NAME" >/dev/null 2>&1; then
        print_warning "Terraform state bucket already exists: gs://$BUCKET_NAME"
    else
        gsutil mb -p "$PROJECT_ID" -l "$REGION" gs://"$BUCKET_NAME"
        gsutil versioning set on gs://"$BUCKET_NAME"
        print_status "Created Terraform state bucket: gs://$BUCKET_NAME"
    fi
}

# Create service account for Terraform
create_service_account() {
    print_status "Creating service account for Terraform..."
    
    SA_NAME="terraform-sa"
    SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
    
    # Check if service account exists
    if gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" >/dev/null 2>&1; then
        print_warning "Service account already exists: $SA_EMAIL"
    else
        gcloud iam service-accounts create "$SA_NAME" \
            --display-name="Terraform Service Account" \
            --description="Service account for Terraform deployments" \
            --project="$PROJECT_ID"
        
        print_status "Created service account: $SA_EMAIL"
    fi
    
    # Assign required roles
    roles=(
        "roles/editor"
        "roles/cloudsql.admin"
        "roles/storage.admin"
        "roles/run.admin"
        "roles/compute.admin"
        "roles/secretmanager.admin"
        "roles/iam.serviceAccountAdmin"
        "roles/resourcemanager.projectIamAdmin"
    )
    
    print_status "Assigning roles to service account..."
    for role in "${roles[@]}"; do
        gcloud projects add-iam-policy-binding "$PROJECT_ID" \
            --member="serviceAccount:$SA_EMAIL" \
            --role="$role" \
            --quiet
    done
    
    # Create and download key
    KEY_FILE="terraform-sa-key.json"
    if [ ! -f "$KEY_FILE" ]; then
        gcloud iam service-accounts keys create "$KEY_FILE" \
            --iam-account="$SA_EMAIL" \
            --project="$PROJECT_ID"
        print_status "Service account key created: $KEY_FILE"
        print_warning "Keep this key file secure and do not commit it to version control!"
    else
        print_warning "Service account key file already exists: $KEY_FILE"
    fi
}

# Initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    
    cd infra/terraform
    
    # Update backend configuration
    sed -i.bak "s/YOUR_PROJECT_ID/$PROJECT_ID/g" providers.tf
    
    # Initialize Terraform
    terraform init
    
    # Create workspace for environment if it doesn't exist
    if ! terraform workspace list | grep -q "$ENVIRONMENT"; then
        terraform workspace new "$ENVIRONMENT"
    else
        terraform workspace select "$ENVIRONMENT"
    fi
    
    print_status "Terraform initialized successfully!"
    cd ../..
}

# Create environment file template
create_env_template() {
    print_status "Creating environment configuration template..."
    
    ENV_FILE="infra/terraform/environments/$ENVIRONMENT/secrets.tfvars"
    
    if [ ! -f "$ENV_FILE" ]; then
        cat > "$ENV_FILE" << EOF
# Secrets configuration for $ENVIRONMENT environment
# Fill in these values before running terraform apply

# Medusa Configuration
medusa_publishable_key = "pk_${ENVIRONMENT}_your_medusa_publishable_key_here"

# Stripe Configuration (optional)
stripe_public_key = "pk_${ENVIRONMENT}_your_stripe_public_key_here"

# Database Configuration
db_password = "$(openssl rand -base64 32)"

# Update the main tfvars file with your specific values:
# - project_id
# - medusa_backend_url
# - next_public_base_url
EOF
        
        print_status "Created secrets template: $ENV_FILE"
        print_warning "Please update the values in $ENV_FILE before deploying!"
    else
        print_warning "Secrets file already exists: $ENV_FILE"
    fi
}

# Main setup function
main() {
    print_status "Starting Google Cloud setup for Next.js Medusa Storefront..."
    
    check_prerequisites
    get_project_config
    enable_apis
    create_terraform_state_bucket
    create_service_account
    init_terraform
    create_env_template
    
    print_status "Setup completed successfully!"
    echo
    print_status "Next steps:"
    echo "1. Update the configuration files in infra/terraform/environments/$ENVIRONMENT/"
    echo "2. Fill in the secrets in infra/terraform/environments/$ENVIRONMENT/secrets.tfvars"
    echo "3. Run: ./infra/scripts/deploy.sh $ENVIRONMENT"
    echo
    print_warning "Important: Keep your service account key (terraform-sa-key.json) secure!"
}

# Run main function
main "$@"