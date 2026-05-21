import { test, expect } from "@playwright/test";

test.describe("VailMeds Barcode Scanner - End-to-End Tests", () => {
  test.beforeEach(async ({ page }) => {
    // In production/local development, you would navigate to your dev server
    // For test simulation or server-mounted tests, we mock or use mock components
    await page.goto("http://localhost:3000/"); 
  });

  test("should render the page title and initial scanning state", async ({ page }) => {
    // Validate that the main header is visible
    await expect(page.locator("h1")).toContainText("VailMeds Barcode Scanner");
    
    // Check that scanning status is active
    await expect(page.locator("text=Scanning active...")).toBeVisible();

    // Verify the barcode text is rendered inside the animated scan loader
    const barcodeText = page.locator("span.animate-cut");
    await expect(barcodeText).toBeVisible();
    await expect(barcodeText).toContainText("Barcode");
  });

  test("should include required laser classes for the scanning effect", async ({ page }) => {
    // Assert presence of keyframe scan loader bars
    const scanBars = page.locator(".animate-scan");
    await expect(scanBars).toHaveCount(2);

    // Assert custom polygon cut effect class is present
    const cutEffect = page.locator(".animate-cut");
    await expect(cutEffect).toHaveCount(1);
  });

  test("should allow pausing and restarting the barcode scan", async ({ page }) => {
    // Locate toggle button
    const actionButton = page.locator("button");
    await expect(actionButton).toContainText("Pause Scan");

    // Click to pause the scanner
    await actionButton.click();

    // Validate that scanning is paused and success message is displayed
    await expect(actionButton).toContainText("Restart Scan");
    await expect(page.locator("text=Scanning active...")).not.toBeVisible();
    await expect(page.locator("text=Barcode Read Successfully")).toBeVisible();
    await expect(page.locator("text=Generic Acetaminophen - 500mg")).toBeVisible();

    // Click again to resume scanning
    await actionButton.click();

    // Verify scan has resumed
    await expect(actionButton).toContainText("Pause Scan");
    await expect(page.locator("text=Scanning active...")).toBeVisible();
    await expect(page.locator("text=Barcode Read Successfully")).not.toBeVisible();
  });
});
