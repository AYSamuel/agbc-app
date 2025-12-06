# Privacy Policy Hosting Setup

This directory contains the privacy policy for GRACE PORTAL, hosted via GitHub Pages.

## Setup Instructions

### Step 1: Enable GitHub Pages

1. Push this code to your GitHub repository
2. Go to your repository on GitHub
3. Navigate to **Settings** → **Pages** (in the left sidebar)
4. Under "Source", select:
   - **Branch:** `main` (or your default branch)
   - **Folder:** `/docs`
5. Click **Save**
6. Wait a few minutes for GitHub to build and deploy your site

### Step 2: Get Your Privacy Policy URL

After GitHub Pages is enabled, your privacy policy will be available at:

```
https://[YOUR-GITHUB-USERNAME].github.io/agbc-app/
```

Replace `[YOUR-GITHUB-USERNAME]` with your actual GitHub username.

### Step 3: Update Contact Information

**IMPORTANT:** Before submitting to Google Play Store, edit `index.html` and replace the placeholders with your actual contact information:

- `[YOUR CONTACT EMAIL]` - Replace with your church or support email
- `[YOUR CHURCH ADDRESS]` - Replace with your church's physical address
- `[YOUR CONTACT PHONE]` - Replace with your contact phone number

Search for these placeholders in the file (around line 204) and update them.

### Step 4: Add URL to Google Play Console

1. Log in to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Go to **Store presence** → **Store listing**
4. Scroll to the "Privacy policy" section
5. Paste your privacy policy URL: `https://[YOUR-USERNAME].github.io/agbc-app/`
6. Save your changes

## Verification

To verify your privacy policy is live:
1. Visit the URL in your browser
2. Ensure all sections display correctly
3. Confirm your contact information is visible (not placeholder text)
4. Test on mobile devices to ensure responsive design works

## Updating the Privacy Policy

To make changes to your privacy policy:
1. Edit `docs/index.html`
2. Commit and push to GitHub
3. Changes will automatically deploy to GitHub Pages within a few minutes
4. No need to update the URL in Google Play Console (it stays the same)

## Alternative Hosting Options

If you prefer not to use GitHub Pages, you can also host this HTML file on:
- Netlify
- Vercel
- Your church's existing website
- Google Sites
- Any web hosting service

Just copy the `index.html` file to your preferred hosting service and use that URL in the Play Store listing.
