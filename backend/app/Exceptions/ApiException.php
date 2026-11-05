<?php

namespace App\Exceptions;

use App\Support\ResponsApi;
use Illuminate\Http\JsonResponse;
use RuntimeException;

class ApiException extends RuntimeException
{
    /**
     * @param  array<string, mixed>|null  $errors
     */
    public function __construct(
        string $message,
        int $code = 400,
        public readonly mixed $data = null,
        public readonly ?array $errors = null,
    ) {
        parent::__construct($message, $code);
    }

    public function render(): JsonResponse
    {
        return ResponsApi::gagal($this->getMessage(), $this->getCode(), $this->data, $this->errors);
    }
}
