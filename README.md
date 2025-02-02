# Distributed Tracing in Server-Side Swift

Slides and demo from [my talk at FOSDEM 25](https://fosdem.org/2025/schedule/event/fosdem-2025-5218-distributed-tracing-in-server-side-swift/).

## Running the demo

You need to have Docker and Swift installed on your system.

### 1. Start Docker Compose Services

```bash
docker compose up -d
```

### 2. Migrate and seed Product Catalog DB

```bash
cd services/product-catalog
swift run productcatalogctl migrate
swift run productcatalogctl seed
```

### 3. Start Swift Services

```bash
cd services/api
swift run apictl serve

# in another Terminal ...
cd services/api
swift run apictl serve

# in another Terminal ...
cd services/cart
swift run cartctl serve

# in another Terminal ...
cd services/product-catalog
swift run productcatalogctl serve

# in another Terminal ...
cd services/recommendation
swift run productcatalogctl serve

# in another Terminal ...
curl -X POST http://localhost:8083/cart/FOSDEM-2025-TSH-001
```
