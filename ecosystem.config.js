module.exports = {
  apps: [
    {
      name: "financas",
      script: "./backend/dist/index.js",
      cwd: "/home/univates/financas",
      instances: 1,
      autorestart: true,
      watch: false,
      env: {
        NODE_ENV: "production",
        PORT: 3000,
        STATIC_PATH: "/home/univates/financas/frontend/dist",
      },
    },
  ],
};
