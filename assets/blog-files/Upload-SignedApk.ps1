param(
  [System.IO.FileInfo]$file = $null,
  [string]$versioncode = $null,
  [string]$versionname = $null,
  [string]$buildname = $null,
  [string]$apiurl = $null
);

$CODEPAGE = "iso-8859-1";

#--------------------------------------------------------------------------------------------
# function Get-EncodedDataFromFile
#--------------------------------------------------------------------------------------------
function Get-EncodedDataFromFile()
{
  param(
    [System.IO.FileInfo]$file = $null,
    [string]$codePageName = $CODEPAGE
  );
  
  $data = $null;

  if ( $file -and [System.IO.File]::Exists($file.FullName) )
  {
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName);
    if ( $bytes )
    {
      $enc = [System.Text.Encoding]::GetEncoding($codePageName);
      $data = $enc.GetString($bytes);
    }
  }
  else
  {
    Write-Host "ERROR; File '$file' does not exist";
  }
  $data;
}

#----------------------------------------------------------------------------
# function Execute-HTTPPutCommand
#----------------------------------------------------------------------------
function Execute-HTTPPutCommand()
{
  param(
    [string] $url = $null,
    [string] $data = $null,
    [System.Net.NetworkCredential]$credentials = $null,
    [string] $contentType = "application/x-www-form-urlencoded",
    [string] $codePageName = "UTF-8",
    [string] $userAgent = $null
  );

  if ( $url -and $data )
  {
    [System.Net.WebRequest]$webRequest = [System.Net.WebRequest]::Create($url);
    $webRequest.ServicePoint.Expect100Continue = $false;
    if ( $credentials )
    {
      $webRequest.Credentials = $credentials;
      $webRequest.PreAuthenticate = $true;
    }
    $webRequest.ContentType = $contentType;
    $webRequest.Method = "PUT";
    if ( $userAgent )
    {
      $webRequest.UserAgent = $userAgent;
    }
    
    $enc = [System.Text.Encoding]::GetEncoding($codePageName);
    [byte[]]$bytes = $enc.GetBytes($data);
    $webRequest.ContentLength = $bytes.Length;
    [System.IO.Stream]$reqStream = $webRequest.GetRequestStream();
    $reqStream.Write($bytes, 0, $bytes.Length);
    $reqStream.Flush();
    
    $resp = $webRequest.GetResponse();
    $rs = $resp.GetResponseStream();
    [System.IO.StreamReader]$sr = New-Object System.IO.StreamReader -argumentList $rs;
    $sr.ReadToEnd();
  }
}

#--------------------------------------------------------------------------------------------
# function Upload-SignedApk
#--------------------------------------------------------------------------------------------
function Upload-SignedApk()
{
  param
  (
    [System.IO.FileInfo]$file = $null
  );
  
  if ( $file )
  {
    $boundary = [System.Guid]::NewGuid().ToString();
    $header = "--{0}" -f $boundary;
    $footer = "--{0}--" -f $boundary;
  
    [System.Text.StringBuilder]$contents = New-Object System.Text.StringBuilder;
    [void]$contents.AppendLine($header);

    $filedata = Get-EncodedDataFromFile -file $file -codePageName $CODEPAGE;
    if ( $filedata )
    {
      $fileContentType = "application/vnd.android.package-archive";
      $fileHeader = "Content-Disposition: form-data; name=""{0}""; filename=""{1}""" -f "apkFile", $file.Name;

      [void]$contents.AppendLine($fileHeader);
      [void]$contents.AppendLine("Content-Type: {0}" -f $fileContentType);
      [void]$contents.AppendLine();
      [void]$contents.AppendLine($fileData);

      [void]$contents.AppendLine($header);
      [void]$contents.AppendLine("Content-Disposition: form-data; name=""VersionCode""");
      [void]$contents.AppendLine();
      [void]$contents.AppendLine($versioncode);

      [void]$contents.AppendLine($header);
      [void]$contents.AppendLine("Content-Disposition: form-data; name=""VersionName""");
      [void]$contents.AppendLine();
      [void]$contents.AppendLine($versionname);

      [void]$contents.AppendLine($header);
      [void]$contents.AppendLine("Content-Disposition: form-data; name=""BuildName""");
      [void]$contents.AppendLine();
      [void]$contents.AppendLine($buildname);
      
      [void]$contents.AppendLine($footer);
      
      $contents.ToString() > ".\out.txt";
      
      $putContentType = "multipart/form-data; boundary={0}" -f $boundary;
      
      [xml]$resp = Execute-HTTPPutCommand -url $apiurl -data $contents.ToString() -contentType $putContentType -codePageName $CODEPAGE -userAgent "TeamServiceAutomaticBuild";
      
      if ( $resp )
      {
        switch ($resp.rsp.stat)
        {
          "ok" {
            $obj = 1 | select mediaid, mediaurl;
            $obj.mediaid = $resp.rsp.mediaid;
            $obj.mediaurl = $resp.rsp.mediaurl;
            $obj;
          }
          "fail" {
            $errcode = $resp.rsp.err.code;
            $errmsg = $resp.rsp.err.msg;
            Write-Host "Post Error: Code = '$errcode'; Message = '$errmsg'";
          }
        }
      }
    }
  }
  else
  {
    Write-Host "USAGE: Upload-SignedApk.ps1 -versioncode versioncode -versionname versionname -buildname buildname -apiurl apiurl -file file";
  }
}

if ( $file -and $versioncode -and $versionname -and $buildname -and $apiurl )
{
  Upload-SignedApk -file $file;
}
else
{
  Write-Host "USAGE: Upload-SignedApk.ps1 -versioncode versioncode -versionname versionname -buildname buildname -apiurl apiurl -file file";
}