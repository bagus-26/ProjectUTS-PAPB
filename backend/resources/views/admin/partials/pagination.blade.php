@if ($paginator->hasPages())
    <div class="pager">
        <span>
            Menampilkan {{ $paginator->firstItem() }}–{{ $paginator->lastItem() }}
            dari {{ $paginator->total() }} data
        </span>
        <div class="pager-buttons">
            @if ($paginator->onFirstPage())
                <span class="btn btn-sm btn-outline disabled">Sebelumnya</span>
            @else
                <a class="btn btn-sm btn-outline" href="{{ $paginator->previousPageUrl() }}">Sebelumnya</a>
            @endif

            <span class="pager-current">Halaman {{ $paginator->currentPage() }} / {{ $paginator->lastPage() }}</span>

            @if ($paginator->hasMorePages())
                <a class="btn btn-sm btn-outline" href="{{ $paginator->nextPageUrl() }}">Berikutnya</a>
            @else
                <span class="btn btn-sm btn-outline disabled">Berikutnya</span>
            @endif
        </div>
    </div>
@endif
