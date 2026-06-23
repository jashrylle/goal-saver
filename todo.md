Plan: Transform Goal Saver into Product Savings Tracker
TL;DR: Convert your app from a generic financial tracker into a focused Product Savings Tracker. Users will enter products/items they want to buy, track savings toward them, and see visual milestones (25/50/75/100%), money needed, and estimated time to purchase. The system supports both auto-suggested deposits (based on deadline) and manual entries with detailed notes. Includes gamification (achievements), analytics, and optional per-goal notifications. Default currency: ₱ (PHP).

Steps
Phase 1: Data Model Restructuring
Enhance SavingsGoal model to emphasize products:

Add: productName (primary), productDescription (optional), notificationsEnabled (per-goal toggle)
Add computed: moneyNeeded (target - saved), savingsPerDay/Week/Month
Update: recommendedDeposit to auto-calculate based on remaining days and amount
Enhance SavingsLog model:

Add: entryType ("manual", "suggested", "auto"), notes (optional)
Create SavingsMilestone model:

Track which milestones (25%, 50%, 75%, 100%) have been reached
Store reachedDate for each
Update GoalCategory descriptions with product examples (already has good categories)

Phase 2: UI/UX for Product-Centric Experience (can run parallel with Phase 1)
Redesign HomeDashboard:

Hero: "Products You're Saving For" (instead of "Your Goals")
Card shows: product name (big) + money needed + % progress + days left + milestone dots
Quick "Add Savings" button on each card
Create Detailed Savings Entry Screen:

Step 1: Select product → Step 2: Amount → Step 3: Date (default today) → Step 4: Optional notes
Show suggestion: "Save ₱X/week to reach your goal on time"
Update Analytics Dashboard:

Product-level insights: "Avg time to complete", "Savings pace", "Milestones unlocked this month"
Add new widgets:

MilestoneIndicator (4 checkpoint dots for 25/50/75/100%)
SavingsProgressBar (progress bar with milestone markers)
Update cards to show "money needed" prominently
Phase 3: Business Logic & State Management
Enhance GoalSaverController:

Update addSavings() to accept date and notes
Add getSuggestedDeposit(goalId) → calculates daily/weekly/monthly based on deadline
Add getMilestonesForGoal(goalId) → returns which milestones are reached
Add getTotalMoneyNeeded() → sum of all remaining amounts
Refactor method names for product semantics (internal; keep API stable)

Phase 4: Content & Messaging
Update all UI text:

Buttons: "Add Product" (not "Add Goal")
Headers: "Products I'm Saving For", "Money Needed"
Onboarding: "Save for the products you want"
Empty state: "No products saved yet. Add your first item!"
Update seed data with realistic products:

Laptop (₱35K), AirPods (₱8.99K), Tokyo Flight (₱15K), Textbooks (₱6K), etc.
Phase 5: Verification & Polish
Validate calculations (milestone thresholds, money needed, suggested deposits)

Test edge cases (saving over target, editing amounts, paused goals, etc.)

Relevant Files
File	What to modify/create
goal_model.dart	Add productName, notificationsEnabled, moneyNeeded computed property; create SavingsMilestone class; update SavingsLog
goal_controller.dart	Implement getSuggestedDeposit(), getMilestonesForGoal(), getTotalMoneyNeeded()
main.dart	Update GoalSaverController.addSavings() for date/notes; refactor screens for product messaging; update seed data
common_widgets.dart	Add MilestoneIndicator, SavingsProgressBar widgets; update goal card layout
currency_formatter.dart	Ensure PHP (₱) is prominent/default
Verification Checklist
Functional:

 User creates product goal (name, target, deadline) → app calculates money needed and suggested deposit
 Milestones appear at 25/50/75/100% and update when savings added
 Detailed entry flow captures: product, amount, date, notes
 Analytics show product-level insights
 Per-goal notification toggle persists
UI/UX:

 Product name is visually prominent
 "Money needed" and milestones are clear
 Savings entry is minimal taps
 Messaging uses "product/item" language throughout
Content:

 All labels updated ("Add Product", "Products I'm Saving For")
 Seed data has realistic products with ₱ currency
 Onboarding explains the concept
Decisions Made
Significant restructuring: Not just rebranding; emphasizing the product as the core concept
Currency: PHP (₱) as default; multi-currency deferred to v2
Entry flow: 4-step detailed flow (product → amount → date → notes)
Milestones: Visual 25/50/75/100% checkpoints for engagement
Notifications: Per-goal UI toggle now; backend implementation deferred to v2
v1 scope: Include analytics + achievements; skip social sharing & multi-account
Approval
Does this plan align with your vision? Should I proceed with implementation, or would you like to adjust anything (phases, features, timelines, etc.)?