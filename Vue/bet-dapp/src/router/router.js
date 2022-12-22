import { createRouter, createWebHistory } from "vue-router";

import BettingDapp from "@/components/betting-dapp";

const routes = [
  {
    path: "/",
    name: "betting-dapp",
    component: BettingDapp,
  },
];

const router = createRouter({
  history: createWebHistory(process.env.BASE_URL),
  routes,
});

export default router;
