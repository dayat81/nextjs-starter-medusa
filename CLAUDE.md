# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Next.js 15 e-commerce storefront built with the Medusa v2 headless commerce platform. It uses:

- **Next.js 15** with App Router, Server Components, and Server Actions
- **Medusa v2** headless commerce backend via `@medusajs/js-sdk`
- **TypeScript** for type safety
- **Tailwind CSS** with `@medusajs/ui-preset` for styling
- **Yarn** for package management (v3.2.3)

## Development Commands

```bash
# Start development server with turbopack on port 8000
yarn dev

# Production build
yarn build

# Start production server on port 8000
yarn start

# Run ESLint
yarn lint

# Analyze bundle size
yarn analyze
```

## Environment Setup

1. Copy environment template: `cp .env.template .env.local`
2. Required environment variables:
   - `NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY` - Medusa publishable API key
   - `MEDUSA_BACKEND_URL` - Medusa server URL (default: http://localhost:9000)
   - `NEXT_PUBLIC_BASE_URL` - Storefront URL (default: http://localhost:8000)
   - `NEXT_PUBLIC_DEFAULT_REGION` - Default region code (default: us)
   - `NEXT_PUBLIC_STRIPE_KEY` - Stripe public key (optional)

## Architecture

### Route Structure
- **`/[countryCode]/`** - Country/region-based routing with middleware
- **Main pages**: product catalog, cart, checkout, account, orders
- **Checkout flow**: address → delivery → payment → confirmation

### Data Layer (`src/lib/data/`)
- **Server Actions** for all data mutations (cart, orders, customer)
- **Direct SDK calls** for data fetching with Next.js caching
- **Cookie-based** cart and authentication state management

### Key Modules (`src/modules/`)
- **`products/`** - Product display, gallery, actions, related products
- **`cart/`** - Cart management, line items, totals
- **`checkout/`** - Multi-step checkout flow with address/payment
- **`account/`** - Customer authentication, profile, order history
- **`layout/`** - Navigation, footer, country selector

### State Management
- **Cart state**: Cookie-based cart ID with server-side retrieval
- **Region/Country**: URL-based with middleware for region detection
- **Authentication**: Cookie-based with Medusa customer sessions

### Styling
- **Tailwind CSS** with custom design system
- **`@medusajs/ui`** component library
- **Custom breakpoints**: 2xsmall, xsmall, small, medium, large, xlarge, 2xlarge
- **Dark mode support** with `class` strategy

## Testing and Quality

- **ESLint**: Runs with `yarn lint` (builds ignore ESLint errors in production)
- **TypeScript**: Strict mode enabled (builds ignore TS errors in production)
- **Environment validation**: Automatic check for required environment variables

## Deployment Notes

- **Port 8000**: Both dev and production servers run on port 8000
- **Static assets**: Configured for localhost and AWS S3 images
- **Middleware**: Handles region detection and URL rewrites for internationalization
- **Caching**: Aggressive Next.js cache strategies with revalidation tags

## Common Development Patterns

- Use Server Actions for mutations (cart operations, checkout)
- Implement proper error handling with `medusaError` utility
- Follow existing component patterns in `src/modules/`
- Use `retrieveCart()` and `getOrSetCart()` for cart operations
- Implement proper cache revalidation after data mutations