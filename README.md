# Genius Park — Live Deployment (Vercel + GitHub + Supabase)

This folder is the **complete live website**. It contains only the two apps + a launcher —
no business documents, no `node_modules`. Put *the contents of this folder* in a GitHub repo
and Vercel will serve it.

```
index.html                                 → front door, redirects to GPOS
GPOS.html                                  → CEO Command Center + login gate
GP-Head-of-Ops-QC-Command-Center.html      → Head of Ops & QC portal
```

The two apps link to each other (GPOS gate → Command Center, and ◀ GPOS back). Both talk to
the **same Supabase cloud**, so once cloud is on, data syncs live across everyone.

---

## STEP 1 — Put it on GitHub (5 min, no command line)
1. Go to **github.com → New repository**. Name it e.g. `genius-park` → **Private** → Create.
2. On the empty repo page click **“uploading an existing file.”**
3. Drag in **all the files from this `Genius-Park-Live` folder** (index.html, GPOS.html,
   GP-Head-of-Ops-QC-Command-Center.html, .gitignore, README.md) → **Commit changes.**

## STEP 2 — Deploy on Vercel (3 min)
1. Go to **vercel.com → Sign up with GitHub.**
2. **Add New → Project → Import** your `genius-park` repo.
3. Framework Preset: **Other**. Build Command: **leave empty**. Output Directory: **leave as `.` / root.**
4. **Deploy.** You get a live URL like `https://genius-park.vercel.app`.
   - That URL opens GPOS (the front door). The Command Center button is on the gate.

> Future updates: edit a file → push to GitHub → Vercel **auto-redeploys**. That's the whole loop.

## STEP 3 — Turn on the Supabase cloud (the live data + real logins)
Cloud is what makes logins real and data sync across people. It's **OFF until you do this once.**
1. In **Supabase → SQL Editor → New query**, open **`supabase-setup.sql`** from this folder,
   paste the whole thing, and **Run**. That one file sets up BOTH apps (GPOS + Command Center).
2. **Supabase → Authentication → Users → Add user** (tick *Auto Confirm*) for each person.
   **The FIRST user you create becomes MD/Admin automatically.** Give each staff their email + password.
3. In the **live** GPOS and Command Center: enable cloud, **reload**, then on the login screen use
   **☁ Cloud sign-in** with the email/password from step 2.
4. *(Optional but recommended)* Supabase → Authentication → **URL Configuration** → add your Vercel
   URL to **Site URL / Redirect URLs**.

## STEP 4 — Go live for the team
1. Signed in as MD on the live site: **Settings → Clear to Blank** to remove the demo data.
2. Enter (or import) your real students/leads.
3. **Command Center → Access Management** (and Supabase Users) → give each person their own login.
4. Share the Vercel URL. Everyone opens the same URL, signs in, sees only what their role allows,
   and edits sync live.

---

## Good to know
- **Cost:** Supabase free tier + Vercel free tier = **₹0 to start.** Upgrade only as volume grows.
- **Security:** real security = Supabase Auth + the SQL row-rules (revenue/finance are server-locked).
  The in-app local logins are a convenience layer; for live use, rely on **☁ Cloud sign-in**.
- **The 5 access rules** (revenue = MD only, private commissions, ambassador scoping, Head-assigns-leads)
  are enforced in the UI and mirrored by the Supabase row-rules.
- **Custom domain** (e.g. `os.geniuspark.com`): Vercel → Project → Settings → Domains → add it. Optional, later.
- **Ambassador → Ops bridge:** once cloud is on, a Lead Ambassador forwarding a genuine lead in GPOS
  lands live in the Head of Ops intake queue (via the `scos_leads_inbox` table).

*Prepared by Jarvis — virtual Head of Operations & QC.*
