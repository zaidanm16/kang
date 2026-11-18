import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://zaidanm16.github.io',
  base: '/kang',
  integrations: [
    starlight({
    title: 'Kang',
    favicon: '/kang-logo.svg',
    locales: { root: { label: 'English', lang: 'en' }, id: { label: 'Bahasa Indonesia', lang: 'id' } },
    components: { SiteTitle: './src/components/SiteTitle.astro' },
    description: 'Manage Kong gateways with Kang. Installation, gateway management, and administration guides.',
    customCss: ['@fontsource/lobster/400.css', '@fontsource/noto-sans-sundanese/600.css', '@fontsource/inter/400.css', '@fontsource/inter/600.css', '@fontsource/inter/700.css', '@fontsource/inter/800.css', './src/styles/kang.css'],
    social: [{ icon: 'github', label: 'Kang installation repository', href: 'https://github.com/zaidanm16/kang-deploy' }],
    sidebar: [
  {
    "label": "About Kang",
    "translations": {
      "id": "Tentang Kang"
    },
    "slug": ""
  },
  {
    "slug": "architecture"
  },
  {
    "label": "Installation",
    "translations": {
      "id": "Instalasi"
    },
    "items": [
      {
        "slug": "installation/docker"
      },
      {
        "slug": "installation/kubernetes"
      },
      {
        "slug": "installation/upgrade"
      },
      {
        "slug": "guides/operations"
      },
      {
        "slug": "guides/monitoring"
      }
    ]
  },
  {
    "label": "Getting started",
    "translations": {
      "id": "Mulai menggunakan"
    },
    "items": [
      {
        "slug": "getting-started/setup"
      },
      {
        "slug": "getting-started/workspace"
      },
      {
        "slug": "getting-started/first-api"
      },
      {
        "slug": "guides/connections"
      }
    ]
  },
  {
    "label": "Gateway Manager",
    "translations": {
      "id": "Gateway Manager"
    },
    "items": [
      {
        "slug": "gateway/overview"
      },
      {
        "slug": "gateway/services"
      },
      {
        "slug": "gateway/routes"
      },
      {
        "slug": "gateway/consumers"
      },
      {
        "slug": "gateway/plugins"
      },
      {
        "slug": "gateway/upstreams"
      },
      {
        "slug": "gateway/certificates"
      },
      {
        "slug": "gateway/vaults"
      },
      {
        "slug": "gateway/keys"
      },
      {
        "slug": "gateway/redis"
      }
    ]
  },
  {
    "label": "Administration",
    "translations": {
      "id": "Administrasi"
    },
    "items": [
      {
        "slug": "administration/users"
      },
      {
        "slug": "administration/organizations-teams"
      },
      {
        "slug": "administration/audit-logs"
      },
      {
        "slug": "administration/snapshots"
      },
      {
        "slug": "administration/migration"
      },
      {
        "slug": "administration/configuration"
      }
    ]
  },
  {
    "label": "Account and plans",
    "translations": {
      "id": "Akun dan paket"
    },
    "items": [
      {
        "slug": "account/profile"
      },
      {
        "slug": "account/preferences"
      },
      {
        "slug": "guides/plans"
      }
    ]
  },
  {
    "slug": "guides/troubleshooting"
  }
],
    }),
  ],
});
