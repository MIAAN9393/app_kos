const jwt = require("jsonwebtoken")
const User = require("../model/user")
require("dotenv").config()

exports.cek_token_and_role = (role=[]) => {
    return (req,res,next) => {

    const authHeader = req.headers.authorization
    // console.log(req.headers.authorizatio)

    if(!authHeader)
        return res.status(400).json({
            success:false,
            code: "TOKEN_HEADER_MISSING",
            pesan:"access_token tidak ada pastikan kamu mengisi Bearer"
        })

    const access_token = authHeader.split(" ")[1]
    
    if(!access_token)
        return res.status(400).json({
            success:false,
            code: "TOKEN_EMPTY",
            pesan:"access_token kosong"
        })

    try {

        const decode = jwt.verify(access_token,process.env.JWT_SECRET)

        if(!role.some(v => v === decode.role)){
            return res.status(403).json({
                success:false,
                code: "ROLE_FORBIDDEN",
                pesan:`role ${decode.role} tidak di izinkan akse halaman ini`
            })
        }

        req.user = decode

        next()

    } catch (error) {
        
        return res.status(403).json({
            success:false,
            code: "INVALID_TOKEN",
            pesan:"access_token tidak valid"
        })

    }

}
}