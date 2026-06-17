const UserService = require("../services/user_service")

exports.register = async (req,res,next)=>{

    try {
        const data = await UserService.register(req.body)
        
        res.status(200).json({
            success:true,
            code: "REGISTER_SUCCESS",
            pesan:"registrasi berhasil",
            data
        })

    } catch (error) {
        next(error)
    }
}

exports.login = async (req,res,next) => {

    try {
        const token = await UserService.login(req.body)

        const dat = {
            success:true,
            code: "LOGIN_SUCCESS",
            pesan:"login berhasil",
            data: token
        }

        console.log(dat)
        
        res.status(200).json(dat)

    } catch (error) {
        next(error)
    }
}

exports.login_google = async (req,res,next) => {

    try {
        const token = await UserService.login_google(req.body)
        
        res.status(200).json({
            success:true,
            code: "LOGIN_GOOGLE_SUCCESS",
            pesan:"login Google berhasil",
            data: token
        })

    } catch (error) {
        next(error)
    }
}

exports.resend_email_verification = async (req,res,next) => {
    try {
        const data = await UserService.resend_email_verification(req.body)

        res.status(200).json({
            success:true,
            code: "EMAIL_VERIFICATION_SENT",
            pesan:"jika email terdaftar dan belum terverifikasi, kode verifikasi akan dikirim",
            data
        })

    } catch (error) {
        next(error)
    }
}

exports.resend_phone_verification = async (req,res,next) => {
    try {
        const data = await UserService.resend_phone_verification(req.body)

        res.status(200).json({
            success:true,
            code: "PHONE_VERIFICATION_SENT",
            pesan:"jika nomor HP terdaftar dan belum terverifikasi, kode verifikasi akan dikirim",
            data
        })

    } catch (error) {
        next(error)
    }
}

exports.verify_email = async (req,res,next) => {
    try {
        const data = await UserService.verify_email(req.body)

        res.status(200).json({
            success:true,
            code: "EMAIL_VERIFIED",
            pesan:"email berhasil diverifikasi",
            data
        })

    } catch (error) {
        next(error)
    }
}

exports.verify_phone = async (req,res,next) => {
    try {
        const data = await UserService.verify_phone(req.body)

        res.status(200).json({
            success:true,
            code: "PHONE_VERIFIED",
            pesan:"nomor HP berhasil diverifikasi",
            data
        })

    } catch (error) {
        next(error)
    }
}

exports.forgot_password = async (req,res,next) => {
    try {
        const data = await UserService.forgot_password(req.body)

        res.status(200).json({
            success:true,
            code: "PASSWORD_RESET_SENT",
            pesan:"jika kontak terdaftar, kode reset password akan dikirim",
            data
        })

    } catch (error) {
        next(error)
    }
}

exports.reset_password = async (req,res,next) => {
    try {
        const data = await UserService.reset_password(req.body)

        res.status(200).json({
            success:true,
            code: "PASSWORD_RESET_SUCCESS",
            pesan:"password berhasil diubah, silakan login",
            data
        })

    } catch (error) {
        next(error)
    }
}

exports.refresh_token = async (req,res,next) => {

    try {
        const data = await UserService.refresh_token(req.body)
        
        res.status(200).json({
            success:true,
            code: "LOGOUT_SUCCESS",
            pesan:"refresh berhasil",
            data
        })

    } catch (error) {
        next(error)
    }
}

exports.logout = async (req,res,next) => {

    try {
        const data = await UserService.logout(req.body)
        
        res.status(200).json({
            success:true,
            code: "LOGOUT_SUCCESS",
            pesan:"logout berhasil",
            data
        })

    } catch (error) {
        next(error)
    }
}
