package com.jakartasmartcity.jakdrain

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.net.Uri
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "jakdrain/camera"
    private var pendingResult: MethodChannel.Result? = null
    private var permissionResultCallback: MethodChannel.Result? = null
    private var currentPhotoPath: String? = null
    private val REQUEST_IMAGE_CAPTURE = 1001
    private val REQUEST_PICK_IMAGE = 1002
    private val REQUEST_CAMERA_PERMISSION = 2001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkCameraPermission" -> {
                    val cameraGranted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.CAMERA
                    ) == PackageManager.PERMISSION_GRANTED
                    val locationGranted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.ACCESS_FINE_LOCATION
                    ) == PackageManager.PERMISSION_GRANTED || ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.ACCESS_COARSE_LOCATION
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(cameraGranted && locationGranted)
                }
                "requestCameraPermission" -> {
                    val needed = mutableListOf<String>()
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
                        needed.add(Manifest.permission.CAMERA)
                    }
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                        needed.add(Manifest.permission.ACCESS_FINE_LOCATION)
                    }
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                        needed.add(Manifest.permission.ACCESS_COARSE_LOCATION)
                    }

                    if (needed.isEmpty()) {
                        result.success(true)
                    } else {
                        permissionResultCallback = result
                        ActivityCompat.requestPermissions(
                            this,
                            needed.toTypedArray(),
                            REQUEST_CAMERA_PERMISSION
                        )
                    }
                }
                "openAppSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.fromParts("package", packageName, null)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", e.message, null)
                    }
                }
                "getCurrentLocation" -> {
                    try {
                        val hasLocationPermission = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.ACCESS_FINE_LOCATION
                        ) == PackageManager.PERMISSION_GRANTED || ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.ACCESS_COARSE_LOCATION
                        ) == PackageManager.PERMISSION_GRANTED

                        if (!hasLocationPermission) {
                            result.success(mapOf(
                                "latitude" to -6.1934,
                                "longitude" to 106.8198,
                                "address" to "Izin Lokasi Belum Aktif di HP",
                                "isReal" to false
                            ))
                            return@setMethodCallHandler
                        }

                        Thread {
                            try {
                                val locationManager = getSystemService(android.content.Context.LOCATION_SERVICE) as android.location.LocationManager
                                var bestLocation: android.location.Location? = null
                                val providers = listOf(
                                    android.location.LocationManager.GPS_PROVIDER,
                                    android.location.LocationManager.NETWORK_PROVIDER,
                                    android.location.LocationManager.PASSIVE_PROVIDER
                                )
                                for (provider in providers) {
                                    if (!locationManager.isProviderEnabled(provider)) continue
                                    val l = locationManager.getLastKnownLocation(provider) ?: continue
                                    if (bestLocation == null || l.time > bestLocation.time || l.accuracy < bestLocation.accuracy) {
                                        bestLocation = l
                                    }
                                }

                                if (bestLocation != null) {
                                    val geocoder = android.location.Geocoder(this, java.util.Locale("id", "ID"))
                                    var addressText = "GPS: ${String.format("%.4f, %.4f", bestLocation.latitude, bestLocation.longitude)}"
                                    var streetName = "Duri Kosambi"
                                    var kelurahanName = "Duri Kosambi"
                                    var kecamatanName = "Kecamatan Cengkareng"
                                    var kotaName = "Kota Jakarta Barat"
                                    var provinsiName = "Daerah Khusus Ibukota Jakarta"

                                    try {
                                        @Suppress("DEPRECATION")
                                        val addresses = geocoder.getFromLocation(bestLocation.latitude, bestLocation.longitude, 1)
                                        if (!addresses.isNullOrEmpty()) {
                                            val addr = addresses[0]
                                            val thoroughfare = addr.thoroughfare ?: ""
                                            val subThoroughfare = addr.subThoroughfare ?: ""
                                            val subLocality = addr.subLocality ?: ""
                                            val locality = addr.locality ?: ""
                                            val subAdmin = addr.subAdminArea ?: ""
                                            val adminArea = addr.adminArea ?: ""
                                            val full = addr.getAddressLine(0) ?: ""

                                            val streetWithNo = if (thoroughfare.isNotEmpty()) {
                                                if (subThoroughfare.isNotEmpty()) "$thoroughfare No. $subThoroughfare" else thoroughfare
                                            } else ""

                                            if (subLocality.isNotEmpty()) {
                                                kelurahanName = subLocality
                                                streetName = if (streetWithNo.isNotEmpty()) streetWithNo else subLocality
                                            } else if (streetWithNo.isNotEmpty()) {
                                                streetName = streetWithNo
                                                kelurahanName = streetWithNo
                                            }

                                            if (locality.isNotEmpty()) {
                                                kecamatanName = if (locality.startsWith("Kecamatan", ignoreCase = true)) locality else "Kecamatan $locality"
                                            }

                                            if (subAdmin.isNotEmpty()) {
                                                kotaName = if (subAdmin.startsWith("Kota", ignoreCase = true) || subAdmin.startsWith("Kabupaten", ignoreCase = true)) subAdmin else "Kota $subAdmin"
                                            }

                                            if (adminArea.isNotEmpty()) {
                                                provinsiName = adminArea
                                            }

                                            addressText = when {
                                                streetWithNo.isNotEmpty() && subLocality.isNotEmpty() ->
                                                    "$streetWithNo, $subLocality"
                                                streetWithNo.isNotEmpty() && locality.isNotEmpty() ->
                                                    "$streetWithNo, $locality"
                                                subLocality.isNotEmpty() && locality.isNotEmpty() ->
                                                    "$subLocality, $locality"
                                                full.isNotEmpty() -> full
                                                else -> "Area $subAdmin"
                                            }
                                        }
                                    } catch (_: Exception) {}

                                    val alt = if (bestLocation.hasAltitude()) bestLocation.altitude else 28.7

                                    runOnUiThread {
                                        result.success(mapOf(
                                            "latitude" to bestLocation.latitude,
                                            "longitude" to bestLocation.longitude,
                                            "altitude" to alt,
                                            "street" to streetName,
                                            "kelurahan" to kelurahanName,
                                            "kecamatan" to kecamatanName,
                                            "kota" to kotaName,
                                            "provinsi" to provinsiName,
                                            "address" to addressText,
                                            "isReal" to true
                                        ))
                                    }
                                } else {
                                    runOnUiThread {
                                        result.success(mapOf(
                                            "latitude" to -6.1754,
                                            "longitude" to 106.8272,
                                            "altitude" to 28.7,
                                            "street" to "Duri Kosambi",
                                            "kelurahan" to "Duri Kosambi",
                                            "kecamatan" to "Kecamatan Cengkareng",
                                            "kota" to "Kota Jakarta Barat",
                                            "provinsi" to "Daerah Khusus Ibukota Jakarta",
                                            "address" to "Duri Kosambi, Cengkareng",
                                            "isReal" to false
                                        ))
                                    }
                                }
                            } catch (e: Exception) {
                                runOnUiThread {
                                    result.success(mapOf(
                                        "latitude" to -6.1754,
                                        "longitude" to 106.8272,
                                        "altitude" to 28.7,
                                        "street" to "Duri Kosambi",
                                        "kelurahan" to "Duri Kosambi",
                                        "kecamatan" to "Kecamatan Cengkareng",
                                        "kota" to "Kota Jakarta Barat",
                                        "provinsi" to "Daerah Khusus Ibukota Jakarta",
                                        "address" to "Duri Kosambi, Cengkareng",
                                        "isReal" to false
                                    ))
                                }
                            }
                        }.start()
                    } catch (e: Exception) {
                        result.success(mapOf(
                            "latitude" to -6.1754,
                            "longitude" to 106.8272,
                            "altitude" to 28.7,
                            "street" to "Duri Kosambi",
                            "kelurahan" to "Duri Kosambi",
                            "kecamatan" to "Kecamatan Cengkareng",
                            "kota" to "Kota Jakarta Barat",
                            "provinsi" to "Daerah Khusus Ibukota Jakarta",
                            "address" to "Duri Kosambi, Cengkareng",
                            "isReal" to false
                        ))
                    }
                }
                "takePhoto" -> {
                    val hasPermission = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.CAMERA
                    ) == PackageManager.PERMISSION_GRANTED

                    if (!hasPermission) {
                        result.error("PERMISSION_DENIED", "Izin kamera belum diberikan pengguna.", null)
                        return@setMethodCallHandler
                    }

                    pendingResult = result
                    try {
                        val photoFile = File(cacheDir, "camera_${System.currentTimeMillis()}.jpg")
                        photoFile.parentFile?.mkdirs()
                        if (!photoFile.exists()) {
                            photoFile.createNewFile()
                        }
                        currentPhotoPath = photoFile.absolutePath

                        val photoUri: Uri = FileProvider.getUriForFile(
                            this,
                            "${applicationContext.packageName}.fileprovider",
                            photoFile
                        )
                        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
                            putExtra(MediaStore.EXTRA_OUTPUT, photoUri)
                            clipData = android.content.ClipData.newRawUri("", photoUri)
                            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }

                        // Grant URI permission explicitly to camera resolver activities for HyperOS / MIUI compatibility
                        val resInfoList = packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
                        for (resolveInfo in resInfoList) {
                            val targetPackage = resolveInfo.activityInfo.packageName
                            grantUriPermission(targetPackage, photoUri, Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }

                        startActivityForResult(intent, REQUEST_IMAGE_CAPTURE)
                    } catch (e: Exception) {
                        currentPhotoPath = null
                        result.error("CAMERA_ERROR", e.message, null)
                        pendingResult = null
                    }
                }
                "pickGallery" -> {
                    pendingResult = result
                    try {
                        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                            type = "image/*"
                            addCategory(Intent.CATEGORY_OPENABLE)
                        }
                        startActivityForResult(Intent.createChooser(intent, "Pilih Foto Drainase"), REQUEST_PICK_IMAGE)
                    } catch (e: Exception) {
                        result.error("GALLERY_ERROR", e.message, null)
                        pendingResult = null
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CAMERA_PERMISSION) {
            val cameraGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
            val locationGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
            permissionResultCallback?.success(cameraGranted && locationGranted)
            permissionResultCallback = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            REQUEST_IMAGE_CAPTURE -> {
                if (resultCode == Activity.RESULT_OK) {
                    val path = currentPhotoPath
                    if (path != null) {
                        val file = File(path)
                        if (file.exists() && file.length() > 0) {
                            pendingResult?.success(path)
                        } else {
                            // Fallback jika kamera perangkat menyimpan bitmap ke extras data
                            val bitmap = data?.extras?.get("data") as? Bitmap
                            if (bitmap != null) {
                                try {
                                    val out = FileOutputStream(file)
                                    bitmap.compress(Bitmap.CompressFormat.JPEG, 90, out)
                                    out.flush()
                                    out.close()
                                    pendingResult?.success(path)
                                } catch (e: Exception) {
                                    pendingResult?.error("SAVE_FAILED", e.message, null)
                                }
                            } else {
                                pendingResult?.success(null)
                            }
                        }
                    } else {
                        pendingResult?.success(null)
                    }
                } else {
                    pendingResult?.success(null)
                }
                currentPhotoPath = null
                pendingResult = null
            }
            REQUEST_PICK_IMAGE -> {
                if (resultCode == Activity.RESULT_OK && data?.data != null) {
                    try {
                        val inputStream: InputStream? = contentResolver.openInputStream(data.data!!)
                        val outFile = File(cacheDir, "gallery_${System.currentTimeMillis()}.jpg")
                        val outputStream = FileOutputStream(outFile)
                        inputStream?.copyTo(outputStream)
                        inputStream?.close()
                        outputStream.close()
                        pendingResult?.success(outFile.absolutePath)
                    } catch (e: Exception) {
                        pendingResult?.error("PICK_FAILED", e.message, null)
                    }
                } else {
                    pendingResult?.success(null)
                }
                pendingResult = null
            }
        }
    }
}
