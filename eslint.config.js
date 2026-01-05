import js from "@eslint/js";
import globals from "globals";
import security from "eslint-plugin-security";
import n from "eslint-plugin-n";
import promise from "eslint-plugin-promise";

export default [
  js.configs.recommended,
  {
    ignores: ["node_modules/**", "dist/**", "coverage/**"],
  },
  {
    files: ["**/*.js"],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      globals: {
        ...globals.node,
      },
    },
    plugins: {
      security,
      n,
      promise,
    },
    rules: {
      "n/no-missing-import": "off",
      "n/no-unsupported-features/es-syntax": "off",
      "security/detect-object-injection": "warn",
      "no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
    },
  },
];
