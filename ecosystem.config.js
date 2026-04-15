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
        // Email vars are loaded from backend/.env by dotenv at startup.
        // This block is kept minimal; secrets live in the .env file on the VM.
      },
    },
  ],
};
