# HANDY HUB — publish and secure the storefront

## 1. Supabase setup (required for Admin Portal)

1. Open the Supabase project: https://bbbzodqqbacbgjmavyqo.supabase.co
2. Go to **SQL Editor → New query**. Open `supabase-setup.sql`, paste its contents and run it.
3. Go to **Authentication → Users → Add user**. Create/confirm `handyhubstore01@gmail.com` and set a strong, unique password. Do not put the password in GitHub or chat.
4. After creating the Auth user, run this separate SQL query:

```sql
insert into public.hh_admins (user_id)
select id from auth.users
where lower(email) = lower('handyhubstore01@gmail.com')
on conflict (user_id) do nothing;
```

5. In **Authentication → URL Configuration**, set Site URL and Redirect URLs to the final site address.

## 2. GitHub Pages

1. This repository contains `index.html` and the three image assets in the repository root.
2. Open **Settings → Pages**.
3. Select **Deploy from a branch**, branch `main`, folder `/ (root)`, then Save.
4. Wait for the deployment to finish. The default Pages URL is based on this repository's owner and name.

## 3. Admin Portal

- Click **Admin Portal** in the header or **Store admin login** in the footer.
- Sign in with the Supabase Auth user created above.
- Only a user whose Auth user ID exists in `public.hh_admins` can manage products.
- Product images are stored in the `hh-products` Storage bucket.

## 4. Security notes

- The browser uses only the Supabase publishable key. It is intended to be public.
- Never put a Supabase `service_role` or secret key in HTML, JavaScript, GitHub, or chat.
- Product write permissions are enforced by Supabase Row Level Security and the `hh_is_admin()` check.
- The `hh-products` bucket is public-read so visitors can see product photos; writes and deletes are restricted to authorized admins.
- This is a product catalogue with WhatsApp enquiries, not a checkout/payment system.

## 5. Test before launch

- Open the storefront in a private/incognito window.
- Test Admin Portal with the authorized admin account.
- Confirm a non-admin account cannot manage products.
- Add a test product and image, refresh, edit it, and delete it.
- Check WhatsApp and Instagram links.

## Store settings

- Supabase project: https://bbbzodqqbacbgjmavyqo.supabase.co
- Admin email: handyhubstore01@gmail.com
- Currency: INR (₹)
- WhatsApp: +91 89215 61497
- Instagram: https://www.instagram.com/handyhub_store?avpt=MXc2bjVjaGJiazh4eA==
- Preferred custom domain: `handyhub.store` (must be registered and DNS/GitHub Pages configured separately).
