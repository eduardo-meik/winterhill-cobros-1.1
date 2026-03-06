Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class CredHelper {
    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool CredRead(string target, int type, int reserved, out IntPtr cred);
    [DllImport("advapi32.dll")]
    public static extern void CredFree(IntPtr cred);
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct CREDENTIAL {
        public int Flags; public int Type; public string TargetName; public string Comment;
        public long LastWritten; public int CredentialBlobSize; public IntPtr CredentialBlob;
        public int Persist; public int AttributeCount; public IntPtr Attributes;
        public string TargetAlias; public string UserName;
    }
    public static string Get(string target) {
        IntPtr ptr;
        if (CredRead(target, 1, 0, out ptr)) {
            CREDENTIAL c = (CREDENTIAL)Marshal.PtrToStructure(ptr, typeof(CREDENTIAL));
            byte[] bytes = new byte[c.CredentialBlobSize];
            Marshal.Copy(c.CredentialBlob, bytes, 0, c.CredentialBlobSize);
            CredFree(ptr);
            return System.Text.Encoding.UTF8.GetString(bytes);
        }
        return null;
    }
}
"@ -ErrorAction SilentlyContinue
$token = [CredHelper]::Get("Supabase CLI:access-token")
if ($token) { Write-Host $token -NoNewline } else { exit 1 }
