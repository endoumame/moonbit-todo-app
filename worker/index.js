import { handle_request } from "../_build/js/release/build/app/app.js";

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const method = request.method;
    const path = url.pathname;
    let body = "";
    if (method === "POST" || method === "PUT" || method === "PATCH") {
      body = await request.text();
    }

    const resultJson = handle_request(method, path, body);
    const result = JSON.parse(resultJson);

    return new Response(result.body, {
      status: result.status,
      headers: {
        "Content-Type": result.content_type,
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
      },
    });
  },
};
