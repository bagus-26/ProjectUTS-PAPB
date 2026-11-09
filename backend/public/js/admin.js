document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('[data-buka-sidebar]').forEach((tombol) => {
        tombol.addEventListener('click', () => {
            document.body.classList.add('sidebar-open');
        });
    });

    document.querySelectorAll('[data-tutup-sidebar]').forEach((elemen) => {
        elemen.addEventListener('click', () => {
            document.body.classList.remove('sidebar-open');
        });
    });

    document.querySelectorAll('form[data-konfirmasi]').forEach((form) => {
        form.addEventListener('submit', (event) => {
            const pesan = form.dataset.konfirmasi || 'Yakin ingin melanjutkan aksi ini?';

            if (!window.confirm(pesan)) {
                event.preventDefault();
            }
        });
    });
});
