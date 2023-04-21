import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'
import wasm from "vite-plugin-wasm";
import { readFileSync } from 'fs';

import nodePolyfills from 'vite-plugin-node-stdlib-browser'

const packageId = readFileSync('../client-scripts/package.id', 'utf8').trim();
const questId = readFileSync('../client-scripts/quest.id', 'utf8').trim();

// https://vitejs.dev/config/
export default defineConfig({

  plugins: [react(), wasm(), nodePolyfills()],

  // optimizeDeps: {
  //   include: ['./src/snarkjs.js'],
  // },
  define: {
    // process: { browser: true },
    'process.env.packageId': JSON.stringify(packageId),
    'process.env.questId': JSON.stringify(questId),
  },
})
