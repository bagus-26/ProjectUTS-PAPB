<?php

namespace App\Exceptions;

use RuntimeException;
use Throwable;

class XenditException extends RuntimeException
{
    public function __construct(
        string $message,
        public readonly mixed $respons = null,
        ?Throwable $previous = null,
    ) {
        parent::__construct($message, 0, $previous);
    }
}
