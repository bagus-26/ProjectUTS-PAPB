<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="color-scheme" content="light">
    <title>Dokumentasi API - Makan Yuk</title>
    <link rel="icon" type="image/png" href="/swagger-ui/makanyuk-app-icon.png">
    <link rel="stylesheet" href="/swagger-ui/swagger-ui.css">
    <link rel="stylesheet" href="/swagger-ui/dokumentasi.css">
</head>
<body>
<header class="top">
    <div class="top__inner">
        <a class="brand" href="/api" aria-label="Makan Yuk - Dokumentasi API">
            <span class="brand__mark">
                <img src="/swagger-ui/makanyuk-app-icon.png" alt="Logo Makan Yuk" width="38" height="38">
            </span>
            <span class="brand__text">
                <small>Dokumentasi API</small>
            </span>
        </a>

        <div class="top__meta">
            <span class="tag">v1.0</span>
            <span class="base">
                <span>Base URL</span>
                <code>127.0.0.1:8000/api</code>
            </span>
            <a class="top__link" href="/api/openapi.json">OpenAPI 3.0</a>
        </div>
    </div>
</header>

<main class="page">
    <div id="swagger-ui"></div>
</main>

<script src="/swagger-ui/swagger-ui-bundle.js"></script>
<script src="/swagger-ui/swagger-ui-standalone-preset.js"></script>
<script>
    window.addEventListener("load", function () {
        window.ui = SwaggerUIBundle({
            url: "/api/openapi.json",
            dom_id: "#swagger-ui",
            deepLinking: true,
            persistAuthorization: true,
            tryItOutEnabled: true,
            docExpansion: "list",
            defaultModelsExpandDepth: -1,
            defaultModelExpandDepth: 1,
            displayRequestDuration: true,
            filter: true,
            validatorUrl: null,
            syntaxHighlight: {
                activated: true,
                theme: "agate"
            },
            presets: [
                SwaggerUIBundle.presets.apis,
                SwaggerUIStandalonePreset
            ],
            plugins: [
                SwaggerUIBundle.plugins.DownloadUrl
            ],
            layout: "BaseLayout"
        });
    });
</script>
</body>
</html>
