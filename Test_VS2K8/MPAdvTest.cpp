// MPAdvTest.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include <windows.h>
#include <stdio.h>
#include <wincrypt.h>
#include <GetDeviceUniqueId.h>
#include <regext.h>
#include <stdlib.h>

// License verification code snippets provided by Microsoft :

#define DEVICE_ID_LENGTH            20

#ifndef ARRAYSIZE
#define ARRAYSIZE(x) ( sizeof(x)/sizeof(x[0]) )
#endif

#define MAX_LICENSE_LENGTH 256

BOOL VerifySignature(LPBYTE pbLicense, const DWORD dwLicense, LPCSTR szData, const DWORD dwData);
HRESULT ByteArrayToHexString(BYTE *pByteArray, size_t cbByteArray, char* pszHexString, size_t chHexString);

BOOL VerifyLicense(LPCSTR pszAppId) {
	HRESULT hr = S_OK;
	BYTE pbLicense[MAX_LICENSE_LENGTH] = {0};
	DWORD cbLicense = sizeof(pbLicense);
	BYTE  pbDeviceID[DEVICE_ID_LENGTH] = {0};
	DWORD cbDeviceID = sizeof(pbDeviceID);
	char szDeviceID[DEVICE_ID_LENGTH*2+1] = {0};
	BOOL bReturn = FALSE;
	char* pszBuffer = NULL;
	DWORD cbBuffer = 0;
	HKEY hKey = NULL;
	DWORD dwRegType;
	size_t chAppId = strlen(pszAppId) + 1;
	WCHAR wszAppId[MAX_LICENSE_LENGTH];
	if (mbstowcs(wszAppId, pszAppId, chAppId) <= 0) {
		goto exit;
	}

	// get license from registry
	if( 
		RegOpenKeyEx(HKEY_CURRENT_USER, L"Security\\Software\\Microsoft\\Marketplace\\Licenses", 0, 0, &hKey) != ERROR_SUCCESS || 
		RegQueryValueEx(hKey, wszAppId, NULL, &dwRegType, (LPBYTE)pbLicense, &cbLicense) != ERROR_SUCCESS ||
		dwRegType != REG_BINARY 
	){
		goto exit;
	}

	// The license is stored Big-endian because it came from .NET APIs. The win32 APIs use little-endian.
	for(UINT i=0; i<cbLicense/2; ++i) {
		char tmp = pbLicense[i];
		pbLicense[i] = pbLicense[cbLicense-i-1];
		pbLicense[cbLicense-i-1] = tmp;
	}

	// Get DeviceID
	const WCHAR wszDeviceKey[] = L"Marketplace";
	hr = GetDeviceUniqueID((BYTE*)wszDeviceKey, sizeof(wszDeviceKey)-sizeof(wszDeviceKey[0]), 1, pbDeviceID, &cbDeviceID);
	if(FAILED(hr)) {
		goto exit;
	}

	// Convert byte array to output string.
	hr = ByteArrayToHexString(pbDeviceID, cbDeviceID, szDeviceID, ARRAYSIZE(szDeviceID));
	cbBuffer = chAppId+strlen(szDeviceID)+1; // +1 for " "
	if( (pszBuffer = (char*)malloc(cbBuffer)) == NULL ) {
		goto exit;
	}

	if( 
		!SUCCEEDED(StringCchCopyA(pszBuffer, cbBuffer, pszAppId)) ||
		!SUCCEEDED(StringCchCatA(pszBuffer, cbBuffer, " ")) || 
		!SUCCEEDED(StringCchCatA(pszBuffer, cbBuffer, szDeviceID)) 
	) {
		goto exit;
	}
	cbBuffer--; // (-1, don't include null term).
	// decrypt license using public key
	bReturn = VerifySignature(pbLicense, cbLicense, pszBuffer, cbBuffer); 

exit:
	if(pszBuffer) {
		delete pszBuffer;
		pszBuffer = NULL;
	}

	if(hKey) {
		RegCloseKey(hKey);
	}

	return bReturn;
}

BOOL VerifySignature(LPBYTE pbLicense, const DWORD dwLicense, LPCSTR szData, const DWORD dwData) {
	HCRYPTPROV hProv = 0;
	HCRYPTHASH hHash = 0;
	HCRYPTKEY hKey = 0;

	// Public key
	const BYTE pbKeyModulus[] = {0x21, 0x12, 0xc3, 0x8a, 0xc8, 0x23, 0xdb, 0x9e, 0x1a, 0x3c, 0x0e, 0x2a, 0x92, 0x60, 0xb9, 0x5c, 0x38, 0x92, 0x45, 0xf2, 0xc2, 0xd1, 0x46, 0x94, 0x71, 0xa3, 0xfc, 0xdb, 0xc2, 0x00, 0xf7, 0xa9, 0x3f, 0x4b, 0xa8, 0x58, 0x4a, 0x1c, 0x67, 0x14, 0xc2, 0x32, 0xc7, 0xb1, 0x5a, 0x55, 0x0a, 0x65, 0x48, 0x9e, 0x00, 0xc5, 0x53, 0xb8, 0xe8, 0xb7, 0x98, 0x10, 0x4d, 0xb9, 0xf3, 0xaf, 0x9f, 0xda, 0xb4, 0x85, 0x55, 0x73, 0xa0, 0xcc, 0xe5, 0xb8, 0x0e, 0x88, 0x8d, 0x49, 0x62, 0xc8, 0x52, 0x26, 0xeb, 0x11, 0xc3, 0x49, 0x01, 0x89, 0x63, 0xab, 0xa1, 0x7e, 0x70, 0x5b, 0xe6, 0xb7, 0xd3, 0x8a, 0x21, 0x49, 0xfd, 0xa3, 0xd0, 0xa2, 0x4f, 0xed, 0xeb, 0x71, 0x14, 0x63, 0x12, 0x4d, 0xff, 0x0e, 0xcd, 0x9d, 0x93, 0xe4, 0x88, 0x26, 0x59, 0x9f, 0xdc, 0x29, 0xcc, 0xa9, 0xda, 0x93, 0x6e, 0x83 };
	const DWORD dwKeyExponent = 0x00010001; // {0x01, 0x00, 0x01}
	BOOL bReturn = FALSE;

	// Get the handle to the default provider.
	if (!CryptAcquireContext (&hProv, NULL, NULL, PROV_RSA_FULL, 0)) {
		DWORD ret = GetLastError();
		if (ret !=  NTE_BAD_KEYSET) {
			goto exit;
		} else {
			if (!CryptAcquireContext (&hProv, NULL, NULL, PROV_RSA_FULL, CRYPT_NEWKEYSET)) {
				goto exit;
			}
		}
	}

	// Initialize Public Key BLOB
	const DWORD cbKeyBlob = sizeof(BLOBHEADER) + sizeof(RSAPUBKEY) + sizeof(pbKeyModulus);
	const BYTE* pbKeyBlob = new BYTE[cbKeyBlob];
	BLOBHEADER* Header = (BLOBHEADER*)pbKeyBlob;
	Header->bType	= PUBLICKEYBLOB;
	Header->bVersion	= CUR_BLOB_VERSION;
	Header->reserved	= 0;
	Header->aiKeyAlg	= CALG_RSA_SIGN;
	RSAPUBKEY* RSAPubKey = (RSAPUBKEY*)( pbKeyBlob + sizeof(BLOBHEADER) );
	RSAPubKey->magic	= 0x31415352;		// "RSA1"
	RSAPubKey->bitlen	= sizeof(pbKeyModulus) * 8;
	RSAPubKey->pubexp	= dwKeyExponent;
	memcpy( (void*)(pbKeyBlob + sizeof(BLOBHEADER) + sizeof(RSAPUBKEY)), 
	pbKeyModulus, sizeof(pbKeyModulus) );

	// Import the key BLOB into the CSP.
	if (!CryptImportKey (hProv, pbKeyBlob, cbKeyBlob, 0, 0, &hKey)) {
		goto exit;
	}

	// Create a new hash object.
	if(!CryptCreateHash(hProv, CALG_SHA1, 0, 0, &hHash)) {
		goto exit;
	}

	// Compute the cryptographic hash of the buffer.
	if(!CryptHashData(hHash, (PBYTE)szData, dwData, 0)) {
		goto exit;
	}

	// Validate the digital signature.
	if(!CryptVerifySignature(hHash, pbLicense, dwLicense, hKey, NULL, 0)) {
		goto exit;
	}
	bReturn = TRUE;

exit:
	// Destroy the session key.
	if (hKey) CryptDestroyKey (hKey);

	// Destroy the hash object.
	if (hHash) CryptDestroyHash (hHash);

	// Release the provider handle.
	if (hProv) CryptReleaseContext (hProv, 0);

	return bReturn;
}

HRESULT ByteArrayToHexString(BYTE *pByteArray, size_t cbByteArray, char* pszHexString, size_t chHexString) {
	const char c_hexList[] = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f' };
	
	// wszHexString must be cbByteArray*2, plus 1 for null terminator.
	if(!pByteArray || cbByteArray == 0 || chHexString < cbByteArray*2+1) {
		return E_INVALIDARG;
	}

	UINT i;
	for (i = 0; i < cbByteArray; i++) {
		pszHexString[i*2] = c_hexList[pByteArray[i] >> 4];
		pszHexString[i*2+1] = c_hexList[pByteArray[i] & 0xF];
	}
	pszHexString[i*2] = L'\0';

	return S_OK;
}

// Test code :

int _tmain(int argc, _TCHAR* argv[])
{
	if (!VerifyLicense("4ce07c0d-2eec-4a59-bf59-457e039f5142")) {
		(void)MessageBox(GetForegroundWindow(), L"You do not have rights to this application. Please download a valid copy from Windows Phone Marketplace.", L"Error", MB_OK);
	} else {
		MessageBox(GetForegroundWindow(), L"License check OK!", L"Error", MB_OK);
	}

	return 0;
}