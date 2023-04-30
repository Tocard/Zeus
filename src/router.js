/* ./src/router.css */

import { createRouter, createWebHistory } from "vue-router";
import Polygon from "./components/Polygon.vue";
import PolygonTestnet from "./components/PolygonTestnet.vue";

export default createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: "/",
      component: Polygon,
    },
    {
      path: "/polygon_testnet",
      component: PolygonTestnet,
    },
  ],
});
