<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Kredensial Xendit
    |--------------------------------------------------------------------------
    |
    | Secret key diambil dari Dashboard Xendit (mode Test atau Live) pada menu
    | Settings > Developers > API Keys. Callback token dipakai untuk
    | memverifikasi header `x-callback-token` pada webhook invoice.
    |
    */

    'secret_key' => env('XENDIT_SECRET_KEY'),

    'callback_token' => env('XENDIT_CALLBACK_TOKEN'),

    'base_url' => env('XENDIT_BASE_URL', 'https://api.xendit.co'),

    'timeout' => (int) env('XENDIT_TIMEOUT', 15),

    /*
    |--------------------------------------------------------------------------
    | Invoice
    |--------------------------------------------------------------------------
    |
    | `invoice_duration` dalam detik. Bila URL redirect dibiarkan kosong,
    | aplikasi memakai host permintaan saat checkout sehingga tautan kembali
    | tetap dapat dibuka dari HP yang terhubung ke jaringan lokal.
    |
    */

    'invoice_duration' => (int) env('XENDIT_INVOICE_DURATION', 86400),

    'success_redirect_url' => env('XENDIT_SUCCESS_REDIRECT_URL'),

    'failure_redirect_url' => env('XENDIT_FAILURE_REDIRECT_URL'),

];
