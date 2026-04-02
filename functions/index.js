const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Trigger: Listens for updates on the /users/{userId} collection.
 * Execution Gate: Only runs when a pharmacy's isAdminApproved field flips from false to true.
 * Action: Triggers the "Clinical Concierge Access Granted" onboarding email.
 */
exports.onPharmacyApproval = onDocumentUpdated("users/{userId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  // If data is somehow missing or not a pharmacy, exit early.
  if (!before || !after || after.role !== 'pharmacy') return;

  // Check the approval transition
  if (!before.isAdminApproved && after.isAdminApproved) {
    const pharmacyEmail = after.email;
    const pharmacyName = after.storeName || after.businessName || after.name || "Pharmacy Partner";
    const licenseNumber = after.licenseNumber || "N/A";

    console.log(`APPROVAL TRIGGERED: Generating welcome email for ${pharmacyName} (${pharmacyEmail}).`);

    // TODO: Integrate actual SendGrid or Resend API call here.
    // Example implementation using a hypothetical sendEmail utility:
    const emailPayload = {
      to: pharmacyEmail,
      subject: "🚀 Access Granted: Your VailMeds Pharmacy Dashboard is Active",
      template: "pharmacy_onboarding_template",
      dynamicData: {
        pharmacyName: pharmacyName,
        licenseNumber: licenseNumber,
        loginUrl: "https://vailmeds.app/pharmacy/login",
        supportUrl: "https://vailmeds.app/support"
      }
    };

    console.log(`Email Payload generated:`, JSON.stringify(emailPayload));
    
    // In production:
    // await sendGrid.send(emailPayload);
  }
});
