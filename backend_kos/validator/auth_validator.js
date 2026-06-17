function validasiEmail(email){
    const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return regex.test(email);
}

function validasiNama(nama){
    const regex = /^[a-zA-Z\s]+$/;
    return regex.test(nama);
}

module.exports = {
    validasiEmail,
    validasiNama
}