const User = require("../model/user")
const Bcrypt = require("bcrypt")
const jwt = require("jsonwebtoken")
const { OAuth2Client } = require("google-auth-library")
const { Op } = require("sequelize")
const {throwError} = require("../utils/error")
const {validasiEmail,validasiNama} = require("../validator/auth_validator")
const { normalizeIndonesianPhoneNumber } = require("../utils/phone_helper")
const AuthOtpService = require("./auth_otp_service")
require("dotenv").config()

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID)

function normalisasiEmail(value) {
    const email = `${value ?? ""}`.trim().toLowerCase()
    if(!email) return null
    if(!validasiEmail(email)){
        throwError("email tidak valid",400,"VALIDATION_ERROR")
    }
    return email
}

function normalisasiPhone(value) {
    return normalizeIndonesianPhoneNumber(value)
}

function channelDariBody(body) {
    return body.channel === "phone" ? "phone" : "email"
}

function kontakDariBody(body) {
    const channel = channelDariBody(body)
    if(channel === "phone"){
        const phone = normalisasiPhone(body.no_telpon ?? body.phone ?? body.identifier)
        if(!phone){
            throwError("nomor HP wajib diisi",400,"VALIDATION_ERROR")
        }
        return {channel, phone}
    }

    const email = normalisasiEmail(body.email ?? body.identifier)
    if(!email){
        throwError("email wajib diisi",400,"VALIDATION_ERROR")
    }
    return {channel, email}
}

function refreshSecret() {
    if(!process.env.JWT_REFRESH_SECRET){
        throwError("JWT_REFRESH_SECRET belum diatur di server",500,"JWT_REFRESH_CONFIG_ERROR")
    }

    return process.env.JWT_REFRESH_SECRET
}

const buatTokenLogin = async (user) => {
    const access_token = jwt.sign(
        {id:user.id,email:user.email,role:user.role},
        process.env.JWT_SECRET,{expiresIn:"2d"}
    )

    const refresh_token = jwt.sign(
        {id:user.id},
        refreshSecret(),{expiresIn:"7d"}
    )

    await user.update({refresh_token:refresh_token})

    return {
        access_token,
        refresh_token
    }
}

exports.register = async (body)=>{
    
    //VALIDASI INPUT
    if(!body.nama||!body.password){
        throwError("data tidak lengkap",400,"VALIDATION_ERROR")
    }

    const kontak = kontakDariBody(body)
    
    if(!validasiNama(body.nama)){
        throwError("nama hanya boleh huruf dan spasi",400,"VALIDATION_ERROR")
    }

    const cek_user = await User.findOne({
        where: kontak.channel === "phone"
            ? {no_telpon:kontak.phone}
            : {email:kontak.email}
    })

    if(cek_user){
        throwError(
            kontak.channel === "phone" ? "nomor HP sudah digunakan" : "email sudah di gunakan",
            400,
            kontak.channel === "phone" ? "PHONE_ALREADY_EXIST" : "EMAIL_ALREADY_EXIST"
        )
    }

    //HASPASWORD
    const hashpassword = await Bcrypt.hash(body.password,10)
    
    //SIMPAN USER
    const user = await User.create({
        nama:body.nama,
        email:kontak.email || null,
        no_telpon:kontak.phone || null,
        password:hashpassword,
        email_verified:false,
        email_verified_at:null,
        phone_verified:false,
        phone_verified_at:null
    })

    const otp = kontak.channel === "phone"
        ? await AuthOtpService.kirimVerifikasiPhone(user)
        : await AuthOtpService.kirimVerifikasiEmail(user)

    return {
        id:user.id,
        nama:user.nama,
        email:user.email,
        no_telpon:user.no_telpon,
        channel:kontak.channel,
        email_verified:user.email_verified,
        phone_verified:user.phone_verified,
        ...otp
    }
}

exports.login = async (body) => {
    
    //VALIDASI
    if(!(body.email||body.no_telpon||body.phone||body.identifier)||!body.password){
        throwError("email/nomor HP dan password wajib diisi",400,"VALIDATION_ERROR")
    }

    const channel = body.channel === "phone" ? "phone" : (
        `${body.identifier ?? body.email ?? ""}`.includes("@") ? "email" : "phone"
    )
    const kontak = kontakDariBody({...body, channel})
    
    //AMBIL DATA USER
    const user = await User.findOne({
        where: channel === "phone"
            ? {no_telpon:kontak.phone}
            : {email:kontak.email}
    })

    if(!user){
        throwError("email/nomor HP atau password salah",401,"INVALID_CREDENTIALS")
    }

    if(!user.password){
        throwError("akun ini terdaftar dengan Google, silahkan login dengan Google",401,"INVALID_CREDENTIALS")
    }

    if(channel === "phone" && !user.phone_verified){
        throwError("nomor HP belum diverifikasi",403,"PHONE_NOT_VERIFIED")
    }

    if(channel === "email" && !user.email_verified){
        throwError("email belum diverifikasi",403,"EMAIL_NOT_VERIFIED")
    }
    
    //CEK HASPASSWORD
    const cocok = await Bcrypt.compare(body.password,user.password)

    if(!cocok){
        throwError("email/nomor HP atau password salah",401,"INVALID_CREDENTIALS")
    }

    return buatTokenLogin(user)
}

exports.login_google = async (body) => {
    const {idToken} = body

    if(!idToken){
        throwError("idToken Google wajib diisi",400,"VALIDATION_ERROR")
    }

    if(!process.env.GOOGLE_CLIENT_ID){
        throwError("GOOGLE_CLIENT_ID belum diatur di server",500,"GOOGLE_CONFIG_ERROR")
    }

    let payload
    try {
        const tiket = await googleClient.verifyIdToken({
            idToken,
            audience: process.env.GOOGLE_CLIENT_ID
        })
        payload = tiket.getPayload()
    } catch (error) {
        throwError("token Google tidak valid",401,"INVALID_GOOGLE_TOKEN")
    }

    if(!payload?.email){
        throwError("email Google tidak ditemukan",400,"GOOGLE_EMAIL_NOT_FOUND")
    }

    if(payload.email_verified === false){
        throwError("email Google belum terverifikasi",401,"GOOGLE_EMAIL_NOT_VERIFIED")
    }

    const email = payload.email.toLowerCase()
    const google_id = payload.sub
    const foto_url = payload.picture || null
    const namaGoogle = payload.name || email.split("@")[0] || "Pengguna Google"

    let user = await User.findOne({
        where:{
            [Op.or]: [
                {email},
                {google_id}
            ]
        }
    })

    if(user){
        const dataUpdate = {}
        if(!user.google_id) dataUpdate.google_id = google_id
        if(foto_url && user.foto_url !== foto_url) dataUpdate.foto_url = foto_url
        if(!user.email_verified){
            dataUpdate.email_verified = true
            dataUpdate.email_verified_at = new Date()
        }
        if(Object.keys(dataUpdate).length > 0){
            await user.update(dataUpdate)
        }
    } else {
        user = await User.create({
            nama:namaGoogle,
            email,
            password:null,
            google_id,
            foto_url,
            email_verified:true,
            email_verified_at:new Date()
        })
    }

    return buatTokenLogin(user)
}

exports.resend_email_verification = async (body) => {
    const email = `${body.email ?? ""}`.trim().toLowerCase()

    if(!email || !validasiEmail(email)){
        throwError("email tidak valid",400,"VALIDATION_ERROR")
    }

    const user = await User.findOne({where:{email}})

    // Jangan bocorkan apakah email terdaftar.
    if(!user){
        return {email}
    }

    if(user.email_verified){
        return {email, email_verified:true}
    }

    const otp = await AuthOtpService.kirimVerifikasiEmail(user)
    return {email, email_verified:false, ...otp}
}

exports.resend_phone_verification = async (body) => {
    const phone = normalisasiPhone(body.no_telpon ?? body.phone ?? body.identifier)

    const user = await User.findOne({where:{no_telpon:phone}})

    // Jangan bocorkan apakah nomor terdaftar.
    if(!user){
        return {no_telpon:phone}
    }

    if(user.phone_verified){
        return {no_telpon:phone, phone_verified:true}
    }

    const otp = await AuthOtpService.kirimVerifikasiPhone(user)
    return {no_telpon:phone, phone_verified:false, ...otp}
}

exports.verify_email = async (body) => {
    const user = await AuthOtpService.verifikasiEmail({
        email:body.email,
        code:body.code
    })

    return {
        email:user.email,
        email_verified:user.email_verified
    }
}

exports.verify_phone = async (body) => {
    const phone = normalisasiPhone(body.no_telpon ?? body.phone ?? body.identifier)
    const user = await AuthOtpService.verifikasiPhone({
        phone,
        code:body.code
    })

    return {
        no_telpon:user.no_telpon,
        phone_verified:user.phone_verified
    }
}

exports.forgot_password = async (body) => {
    const kontak = kontakDariBody(body)

    const user = await User.findOne({
        where: kontak.channel === "phone"
            ? {no_telpon:kontak.phone}
            : {email:kontak.email}
    })

    // Jangan bocorkan apakah email terdaftar.
    if(!user || !user.password){
        return kontak.channel === "phone"
            ? {no_telpon:kontak.phone, channel:kontak.channel}
            : {email:kontak.email, channel:kontak.channel}
    }

    const otp = await AuthOtpService.kirimResetPassword(user, kontak.channel)
    return kontak.channel === "phone"
        ? {no_telpon:kontak.phone, channel:kontak.channel, ...otp}
        : {email:kontak.email, channel:kontak.channel, ...otp}
}

exports.reset_password = async (body) => {
    const kontak = kontakDariBody(body)
    const password_baru = `${body.password_baru ?? body.password ?? ""}`

    if(!password_baru || password_baru.length < 6){
        throwError("password baru minimal 6 karakter",400,"VALIDATION_ERROR")
    }

    const {otp, user} = await AuthOtpService.validasiResetPassword({
        email:kontak.email,
        phone:kontak.phone,
        code:body.code,
        channel:kontak.channel
    })

    const hashpassword = await Bcrypt.hash(password_baru,10)

    await otp.update({used_at:new Date()})
    const payload = {
        password:hashpassword,
        refresh_token:null,
    }
    if(kontak.channel === "phone"){
        payload.phone_verified = true
        payload.phone_verified_at = user.phone_verified_at || new Date()
    } else {
        payload.email_verified = true
        payload.email_verified_at = user.email_verified_at || new Date()
    }

    await user.update(payload)

    return {
        email:user.email,
        no_telpon:user.no_telpon,
        channel:kontak.channel
    }
}

exports.refresh_token = async (body) => {

    const {refresh_token} = body

    //VALIDASI
    if(!refresh_token){
        throwError("refresh token tidak ada",400,"INVALID_CREDENTIAL")
    }

    const secret = refreshSecret()

    //CEK REFRESHTOKEN
    try {

        jwt.verify(refresh_token,secret)

    } catch (error) {
        throwError("refresh token tidak valid silahkan login ulang",401,"INVALID_TOKEN")
    }

    //AMBIL DATA USER
    const user = await User.findOne({where:{refresh_token:refresh_token}})

    if(!user){
        throwError("refresh token tidak valid",401,"INVALID_TOKEN")
    }

    //BUAT TOKEN
    const access_token = jwt.sign({id:user.id,email:user.email,role:user.role},process.env.JWT_SECRET,{"expiresIn":"2d"})
    const new_refresh_token = jwt.sign({id:user.id},secret,{"expiresIn":"7d"})

    //UPDATE DATA USER
    await user.update({refresh_token:new_refresh_token})

    return {
        access_token:access_token,
        refresh_token:new_refresh_token
    }

}

exports.logout = async (body) => {
    
    const {refresh_token} = body

    //VALIDASI
    if(!refresh_token){
        throwError("user belum di tentukan",400,"INVALID_CREDENTIAL")
    }

    //AMBIL DATA USER
    const user = await User.findOne({where:{refresh_token:refresh_token}})

    if(!user){
        throwError("user tidak valid",401,"INVALID_CREDENTIALS")
    }

    //UPDATE DATA USER
    await user.update({refresh_token:null})

    return user
}
