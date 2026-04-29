// Load environment variables from .env files when Prisma CLI runs
import "dotenv/config";

// Minimal Prisma config file that ensures environment variables are loaded.
// Adjust `schema` path or other settings as needed for your project.
export default {
  schema: "prisma/schema.prisma",
  // Prisma will read `DATABASE_URL` from process.env at runtime
};
