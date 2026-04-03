// require("dotenv").config();

// const express = require("express");
// const cors = require("cors");
// const Stripe = require("stripe");

// const app = express();
// const stripe = Stripe(process.env.STRIPE_SECRET_KEY);

// app.use(cors());
// app.use(express.json());

// app.get("/", (req, res) => {
//   res.send("Stripe backend is running");
// });

// app.post("/create-payment-intent", async (req, res) => {
//   try {
//     const { amount, currency = "cad", title } = req.body;

//     if (!amount || amount <= 0) {
//       return res.status(400).json({
//         error: "Amount must be greater than 0",
//       });
//     }

//     const paymentIntent = await stripe.paymentIntents.create({
//       amount: Math.round(amount),
//       currency,
//       automatic_payment_methods: {
//         enabled: true,
//       },
//       description: title ?? "Expense payment",
//     });

//     res.json({
//       clientSecret: paymentIntent.client_secret,
//     });
//   } catch (error) {
//     console.error("Stripe error:", error);
//     res.status(500).json({
//       error: error.message ?? "Failed to create payment intent",
//     });
//   }
// });

// app.listen(process.env.PORT || 3000, () => {
//   console.log(`Server running on port ${process.env.PORT || 3000}`);
// });


require("dotenv").config();

const express = require("express");
const cors = require("cors");
const Stripe = require("stripe");

const app = express();
const stripe = Stripe(process.env.STRIPE_SECRET_KEY);

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.send("Stripe backend is running");
});

app.post("/create-payment-intent", async (req, res) => {
  try {
    const { amount, currency = "cad", title } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({
        error: "Amount must be greater than 0",
      });
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount),
      currency,
      automatic_payment_methods: {
        enabled: true,
      },
      description: title ?? "Expense payment",
    });

    res.json({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (error) {
    console.error("Stripe error:", error);
    res.status(500).json({
      error: error.message ?? "Failed to create payment intent",
    });
  }
});

app.get("/financial-news", async (req, res) => {
  try {
    const apiToken = process.env.MARKETAUX_API_TOKEN;

    if (!apiToken) {
      return res.status(500).json({
        error: "Missing MARKETAUX_API_TOKEN in .env",
      });
    }

    const params = new URLSearchParams({
      api_token: apiToken,
      language: "en",
      countries: "us,ca",
      filter_entities: "true",
      limit: "10",
    });

    const response = await fetch(
      `https://api.marketaux.com/v1/news/all?${params.toString()}`
    );

    const data = await response.json();

    if (!response.ok) {
      return res.status(response.status).json({
        error: data?.error || "Failed to fetch financial news",
      });
    }

    const articles = (data.data || []).map((item) => ({
      title: item.title || "Untitled article",
      description: item.description || "",
      source: item.source || "",
      url: item.url || "",
      imageUrl: item.image_url || "",
      publishedAt: item.published_at || "",
    }));

    res.json({ articles });
  } catch (error) {
    console.error("Financial news error:", error);
    res.status(500).json({
      error: error.message || "Failed to fetch financial news",
    });
  }
});

app.listen(process.env.PORT || 3000, () => {
  console.log(`Server running on port ${process.env.PORT || 3000}`);
});