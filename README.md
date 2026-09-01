# PricePulse

*Your personal price tracking assistant.*

[![Run Tests](https://github.com/KishanYern/PricePulse/actions/workflows/ci.yml/badge.svg)](https://github.com/KishanYern/PricePulse/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

PricePulse is a full-stack web application that allows you to track product prices from your favorite online stores. Simply add a product URL, and PricePulse will monitor it for you, keeping a history of its price changes. This way, you can make sure you're always getting the best deal.

## ✨ Live Demo

You can check out the live version of the application here:
**[https://pricepulselab.com/](https://pricepulselab.com/)**

## 🚀 Key Features

- **User Authentication:** A secure and reliable registration and login system to protect your data.
- **Dynamic Product Tracking:** Track products from a wide range of online retailers by simply providing a product URL. Our flexible scraping tool automatically extracts product details, including name, price, and image.
- **Advanced Price Analytics:** Visualize price trends with an interactive chart that displays the entire price history of a product. The application automatically tracks the current, lowest, and highest prices.
- **Personalized Tracking:** Customize your tracking experience by adding personal notes to each product.
- **Smart Alerts & Notifications:** Set upper and lower price thresholds for your tracked products and receive notifications when the price hits your desired target.
- **Scheduled Price Checks:** The application automatically checks for price updates daily, ensuring you always have the most current information.
- **Admin Dashboard:** A dedicated interface for administrators to view and manage all products in the system.
- **Modern, Responsive UI:** A clean, user-friendly interface built with React and Tailwind CSS, ensuring a seamless experience on any device.

### Screenshots

| Product Dashboard | Product Detail Page |
| :---: | :---: |
| ![Product Dashboard](https://i.imgur.com/AOwMGSh.png) | ![Product Detail Page](https://i.imgur.com/4mMbSRs.png) |
| A view of the main dashboard where users can see all their tracked products at a glance. | A detailed view of a single product, including its price history chart and tracking settings. |

## 🛠️ Tech Stack

### How It Works

1.  **Register and Log In:** Create a secure account to get started.
2.  **Add a Product:** Find a product you want to track on your favorite e-commerce site, copy the URL, and paste it into the "Add Product" form in PricePulse.
3.  **Customize Tracking (Optional):** Add personal notes, set a lower or upper price threshold, and decide if you want to receive notifications.
4.  **Monitor Prices:** PricePulse will automatically check the product's price daily and record any changes.
5.  **View Price History:** Visit the product's page in your dashboard to see a detailed chart of its price history over time.
6.  **Get Notified:** If you've enabled notifications and the price drops below your lower threshold or rises above your upper threshold, you'll receive an alert.

### 🎨 User-Specific Customization

PricePulse allows you to tailor your price-tracking experience to your needs. For each product you track, you can:

- **Add Personal Notes:** Keep track of why you're watching a product, gift ideas, or any other relevant information.
- **Set Price Thresholds:**
    - **Lower Threshold:** Set a price point below which you'd like to be notified—perfect for catching a great deal.
    - **Upper Threshold:** Set a price point above which you'd like to be alerted—ideal for products with fluctuating prices.
- **Toggle Notifications:** Easily enable or disable notifications for each product individually.

This level of customization ensures you only get the alerts that matter most to you.

### Backend

| Tool | Description |
|---|---|
| **FastAPI** | A modern, fast (high-performance), web framework for building APIs with Python. |
| **SQLAlchemy** | The Python SQL toolkit and Object Relational Mapper for database interactions. |
| **PostgreSQL** | A powerful, open-source object-relational database system. |
| **Selenium** | A browser automation framework used for web scraping. |
| **Uvicorn** | A lightning-fast ASGI server implementation. |
| **APScheduler** | A Python library for in-process task scheduling. |

### Frontend

| Tool | Description |
|---|---|
| **React** | A JavaScript library for building user interfaces. |
| **Vite** | A build tool that provides a faster and leaner development experience. |
| **TypeScript** | A typed superset of JavaScript that compiles to plain JavaScript. |
| **Tailwind CSS** | A utility-first CSS framework for rapidly building custom designs. |
| **Axios** | A promise-based HTTP client for making API requests. |
| **React Router DOM** | A standard library for routing in React applications. |
| **React Icons** | A library that provides a wide range of popular icons as React components. |

## 🚀 Deployment & CI/CD

### Deployment

The application is deployed with a modern, decoupled architecture:

-   **Frontend:** React is built into an immutable Docker image and served by nginx on EC2 with TLS.
-   **Backend:** FastAPI runs in a Docker container on a private EC2 address.
-   **Images:** GitHub Actions publishes frontend and backend images to Amazon ECR.
-   **Deployment:** AWS Systems Manager Run Command deploys to EC2 without SSH.

### CI/CD

We use **GitHub Actions** for our Continuous Integration and Continuous Deployment pipeline. Here’s how it works:

-   **On every push** to the `main` branch, the workflow is triggered.
-   **Automated Tests:** It automatically runs the complete test suite for both the backend (using `pytest`) and the frontend (using `vitest`).
-   **Continuous Deployment:** On a successful push to `main`, GitHub authenticates to AWS through OIDC, publishes commit-tagged images to ECR, and deploys both services through SSM.

See [AWS CI/CD setup](docs/aws-cicd.md) for infrastructure and repository variables.

This setup ensures that the code is always in a deployable state and that new changes are integrated smoothly.

## 🏁 Getting Started

### Prerequisites

- **Python:** 3.9+
- **Node.js:** 16+
- **PostgreSQL:** A running instance of PostgreSQL.

### Installation

1.  **Clone the Repository:**
    ```bash
    git clone <repository-url>
    cd pricepulse
    ```

2.  **Backend Setup:**
    ```bash
    cd backend
    pip install -r requirements.txt
    ```

3.  **Frontend Setup:**
    ```bash
    cd ../frontend
    npm install
    ```

### Configuration

Before running the application, you need to set up the environment variables for the backend.

1.  Navigate to the `backend` directory.
2.  Create a file named `.env`.
3.  Add the following environment variables to the `.env` file, replacing the placeholder values with your actual configuration:

    ```env
    # PostgreSQL database URL
    DATABASE_URL="postgresql://user:password@host:port/database"

    # Secret key for JWT token encoding
    SECRET_KEY="your-super-secret-key"

    # Algorithm for JWT token encoding
    ALGORITHM="HS256"

    # Access token expiration time in minutes
    ACCESS_TOKEN_EXPIRE_MINUTES=30
    ```

## 🏃‍♀️ Usage

1.  **Run the backend server:**
    From the `backend` directory, run:
    ```bash
    uvicorn app.main:app --reload
    ```
    The backend will be running on `http://localhost:8000`.

2.  **Run the frontend development server:**
    From the `frontend` directory, run:
    ```bash
    npm run dev
    ```
    The frontend will be running on `http://localhost:5173`.

## 🕒 Scheduled Tasks

PricePulse includes a background task that automatically updates the prices of all tracked products **daily**. This ensures that the price data stays current without requiring manual intervention. When deployed, this task is managed by a scheduled worker on **Render**.

## 🗺️ Roadmap

- [x] **Scheduled Scraping:** A background scheduler automatically checks for price updates at regular intervals.
- [ ] **Email Notifications:** Implement a system to send email alerts when a product's price crosses a user-defined threshold.
- [ ] **User-Facing Admin Dashboard:** Create a dedicated UI for administrators to manage users and products.
- [ ] **Price Alert History:** Allow users to see a history of when price alerts were triggered for their tracked products.
- [ ] **Improve Scraper Robustness:** Enhance the web scraper to handle a wider variety of e-commerce site layouts and improve its reliability.
- [x] **Docker Support:** Production Dockerfiles are used by the AWS CI/CD workflow.

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
