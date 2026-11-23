// VS Code's default TypeScript analyzer does not resolve Deno's remote imports.
// Supabase deploys this file with the Deno runtime and validates these imports there.
// @ts-nocheck
import { serve } from "https://deno.land/std@0.177.1/http/server.ts";
import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";

type PaymentRequestBody = {
  amount?: number;
  checkout?: boolean;
  action?: string;
  sessionId?: string;
  successUrl?: string;
  cancelUrl?: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const stripeSecretKey =
    Deno.env.get("STRIPE_SECRET_KEY") ??
    Deno.env.get("stripe_secret_key") ??
    Deno.env.get("stripe secret key");
  if (!stripeSecretKey) {
    return new Response(
      JSON.stringify({
        error:
          "Falta la variable STRIPE_SECRET_KEY en Supabase. Crea la secret con nombre STRIPE_SECRET_KEY y la clave privada de Stripe.",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const stripe = new Stripe(stripeSecretKey, {
    apiVersion: "2023-10-16",
  });

  try {
    const body = (await req.json()) as PaymentRequestBody;

    if (body.action === "verify_checkout") {
      if (!body.sessionId) {
        return new Response(JSON.stringify({ error: "Falta sessionId." }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const session = await stripe.checkout.sessions.retrieve(body.sessionId);
      return new Response(JSON.stringify({
        paid: session.payment_status === "paid",
        paymentId: session.payment_intent,
      }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const amount = Number(body.amount);

    if (!Number.isFinite(amount) || amount <= 0) {
      return new Response(
        JSON.stringify({ error: "El campo 'amount' es obligatorio y debe ser un número positivo." }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // Stripe recibe COP en su unidad menor: 120000 COP = 12000000 centavos.
    const amountInMinorUnits = Math.round(amount * 100);

    if (body.checkout === true) {
      if (!body.successUrl || !body.cancelUrl) {
        return new Response(
          JSON.stringify({ error: "successUrl y cancelUrl son obligatorios para Checkout." }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      const session = await stripe.checkout.sessions.create({
        mode: "payment",
        line_items: [{
          price_data: {
            currency: "cop",
            product_data: { name: "Compra ModaStyle" },
            unit_amount: amountInMinorUnits,
          },
          quantity: 1,
        }],
        success_url: body.successUrl,
        cancel_url: body.cancelUrl,
      });

      return new Response(
        JSON.stringify({ checkoutUrl: session.url }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountInMinorUnits,
      currency: "cop",
      payment_method_types: ["card"],
    });

    return new Response(
      JSON.stringify({ clientSecret: paymentIntent.client_secret }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error);

    return new Response(JSON.stringify({ error: message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});