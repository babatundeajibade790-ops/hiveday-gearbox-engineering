# Hiveday Gearbox Engineering — Intelligent Workshop Platform

A polished mobile-friendly public website, a browser-based workshop preview, and the secure-backend starter needed to grow into a connected engineering platform.

## Start using it now (no Supabase needed)
1. Unzip the package.
2. Open `public/index.html` in a modern browser to view the public website.
3. Open `public/workshop.html` to use the workshop dashboard preview.
4. In the workshop preview, register vehicles, create repair cases, update statuses, add test results, and export local records as JSON.

The preview stores records in the current browser's local storage. It is not cloud synced, not backed up automatically, and not suitable for storing sensitive customer information. Export records before clearing browser data. The diagnostic helper in preview mode produces a structured checklist; it is not a live AI model.

## Package map
- `public/index.html` — public marketing website with service overview, process, symptom guidance, and contact section.
- `public/workshop.html` — attractive local-first interactive dashboard for immediate preview.
- `public/workshop-cloud.html` — Supabase-connected dashboard starter for use after you create a Supabase project.
- `public/dashboard-prototype.html` — earlier prototype preserved for reference.
- `supabase/schema.sql` — database tables, relationships, and row-level security policies.
- `supabase/functions/diagnostic-assistant/index.ts` — authenticated server-side OpenAI diagnostic-assistant starter.
- `supabase/config.toml` — Supabase function configuration.
- `.env.example` — example configuration names only; no real secrets.

## Before public launch
The public website is configured with phone/WhatsApp +234 901 755 2333. Because an exact physical workshop address was not provided, the site says visits are by appointment and asks customers to request directions on WhatsApp. Replace this with your verified street address if you want it displayed publicly.

## Connect the cloud version later
1. Create a Supabase project.
2. Review `supabase/schema.sql`, then run it in the SQL editor of a new project.
3. Create your workshop login user and keep public signups disabled unless needed.
4. In `public/workshop-cloud.html`, replace `https://YOUR_PROJECT.supabase.co` and `YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY` with the project's public URL and publishable/anon key.
5. Deploy the static `public/` directory using a static host.
6. Deploy the Edge Function using the Supabase CLI. Set `OPENAI_API_KEY`, `OPENAI_MODEL`, and `ALLOWED_ORIGIN` as server-side secrets. Never put an OpenAI key or service-role key in browser HTML.
7. Test sign-in, row-level security with two accounts, create/read/update operations, backups, and the AI function before using real customer records.

## Suggested deployment commands for the AI function
From the project root, after installing the Supabase CLI and linking the project:

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase secrets set OPENAI_API_KEY=YOUR_OPENAI_API_KEY
supabase secrets set OPENAI_MODEL=gpt-4.1-mini
supabase secrets set ALLOWED_ORIGIN=https://YOUR_PUBLIC_SITE_DOMAIN
supabase functions deploy diagnostic-assistant
```

Use a supported model that is available to your API account. API calls may incur costs; configure usage limits and monitoring.

## Engineering and safety principles
- Treat AI output as provisional diagnostic support, never as a confirmed fault.
- Use the exact transmission code and manufacturer service information before applying specifications or test procedures.
- Do not clear codes before preserving useful diagnostic evidence.
- Do not collect unnecessary personal data or full VINs. Apply retention and backup policies.
- The browser preview is for demonstration and early workflow design only. Local storage is not secure cloud storage.
- The cloud starter needs a security review, durable rate limiting, monitoring, strict origin configuration, backup testing, and accessibility/usability checks before production use.

## Brand customization
The brand is set to **Hiveday Gearbox Engineering**. Replace contact details, location, service area, business hours, and any claims that need verification before publication.


Homepage refresh: the public landing page has been rebuilt around the approved visual reference: midnight navy, amber-gold highlights, gear-inspired branding, photographic hero, four service cards, split “Why Hiveday” section, process steps, commitment cards, WhatsApp booking, contact form, and responsive mobile navigation. Hero and workshop photos load from Unsplash and therefore require an internet connection. The contact form prepares a WhatsApp message; it does not store enquiries in a database.
