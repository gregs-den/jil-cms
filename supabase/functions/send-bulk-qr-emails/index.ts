// Save this as: supabase/functions/send-bulk-qr-emails/index.ts
// Deploy with: supabase functions deploy send-bulk-qr-emails

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { members, sender_id } = await req.json();

    if (!members || members.length === 0) {
      return new Response(
        JSON.stringify({ error: "No members provided" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Use SendGrid or your email service
    const SENDGRID_API_KEY = Deno.env.get("SENDGRID_API_KEY");
    if (!SENDGRID_API_KEY) {
      throw new Error("SENDGRID_API_KEY not configured");
    }

    const emailPromises = members.map(async (member: any) => {
      try {
        // Create HTML email with embedded QR code
        const htmlContent = `
          <html>
            <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
                <h2 style="color: white; margin: 0;">Your Member QR Code</h2>
              </div>
              
              <div style="padding: 30px; background: #f8f9fa;">
                <p style="color: #333; font-size: 16px;">Hello ${member.name},</p>
                
                <p style="color: #666; font-size: 14px;">
                  Your QR code has been generated. Below is your personal QR code for check-in and event attendance tracking.
                </p>

                <div style="background: white; padding: 20px; text-align: center; border-radius: 8px; margin: 20px 0;">
                  <img src="${member.qr_data_url}" alt="Member QR Code" style="max-width: 300px; border-radius: 4px;" />
                  <p style="color: #999; font-size: 12px; margin-top: 10px;">
                    Code: <strong>${member.member_code}</strong>
                  </p>
                </div>

                <p style="color: #666; font-size: 14px;">
                  Keep this QR code safe. You'll use it to check in at our events. If you have any questions, please contact our team.
                </p>

                <hr style="border: none; border-top: 1px solid #e8e8e8; margin: 20px 0;">
                
                <p style="color: #999; font-size: 12px; text-align: center;">
                  This is an automated message. Please do not reply to this email.
                </p>
              </div>
            </body>
          </html>
        `;

        const response = await fetch("https://api.sendgrid.com/v3/mail/send", {
          method: "POST",
          headers: {
            Authorization: `Bearer ${SENDGRID_API_KEY}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            personalizations: [
              {
                to: [{ email: member.email, name: member.name }],
                subject: `Your Member QR Code - ${member.member_code}`,
              },
            ],
            from: {
              email: Deno.env.get("SENDER_EMAIL") || "noreply@example.com",
              name: "QR Code System",
            },
            content: [
              {
                type: "text/html",
                value: htmlContent,
              },
            ],
            reply_to: {
              email: Deno.env.get("SUPPORT_EMAIL") || "support@example.com",
            },
          }),
        });

        if (!response.ok) {
          const error = await response.text();
          console.error(`Failed to send email to ${member.email}:`, error);
          return { member_id: member.id, success: false, error };
        }

        return { member_id: member.id, success: true };
      } catch (err) {
        console.error(`Error sending email to ${member.email}:`, err);
        return { member_id: member.id, success: false, error: err.message };
      }
    });

    const results = await Promise.all(emailPromises);
    const successful = results.filter((r) => r.success).length;
    const failed = results.filter((r) => !r.success).length;

    return new Response(
      JSON.stringify({
        success: true,
        total: members.length,
        successful,
        failed,
        details: results,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Error in send-bulk-qr-emails:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});