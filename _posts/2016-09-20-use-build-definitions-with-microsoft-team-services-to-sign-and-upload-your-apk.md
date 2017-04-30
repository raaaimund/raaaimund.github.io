---
layout:     post
title:      Use Build Definitions with Microsoft Team Services to sign and upload your apk
date:       2016-09-20 21:30:00
author:     Raimund Rittnauer
summary:    How to sign and automatic upload an apk when a build is triggered at Microsoft Team Services
categories: tech
thumbnail:  code-fork
tags:
 - microsoft team services
 - ci
 - powershell
 - android
---

For our current project (an Android application) we use the excellent services from Microsoft Visual Studio Team Services.
Mainly we use Team Services for source control and for sprint planning.

In this blog post I want to show how I set up my Build Definition for signing and storing the apk in a MSSQL database after a successful build.

## No Google Play Store
We don't publish our app on Google Play Store, only our employees use this app, so we integrated a custom update manager for our app.
The apk from new releases are stored in our MSSQL database. Using a .Net Core Web API the android clients
can check if there is a new version in the database and the custom update manager downloads and also installs the
new version.

## Create our Build Definition
Team Services provides a really good template for this scenario. I took the Xamarin.Android template and customised this
template.

![create-a-build-definition][create-a-build-definition]{:class="image-responsive"}

Now choose your project, your branch and your agent queue. You can choose between hosted agents or you also can easily
create your own build agent on your machine or on another machine which you use as build server. Also note the
checkbox _Continous integration (build whenever this repository is updated)_. If you check this checkbox an
automatic build is triggered whenever someone checks in at the chosen repository. This is great if you have a production
branch and one or more development branches. Whenever someone merges a finished feature to the production branch
a new build will be triggered and you have a new apk if the build succeeds.

Now you have your new build definitio with these default build steps:

* NuGet restore **/*.sln
   * This step searches all available solution files (every file ending with .sln) and restores all needed NuGet packages
* Xamarin component restore **/*.sln
   * The same like the NuGet restore, but for Xamarin components
* Build Xamarin.Android Project **/*Droid*.csproj
   * This step will build all projects with "Droid" in their name
* Build solution **/*test*.csproj
   * This step will build all projects with "test" in their name (we will skip this)
* Test
   * This step will run your tests on the Xamarin Test Cloud (we will also skip this)
* Signing and aligning APK file(s)
   * This step will sign your apk using your keytore file
* Publish Artifact: drop
   * This step will publish your artifacts (dlls, apks, ...) for you and you can download them if you want to

You can get more details at the [Team Services documentation at the section build][2]{:target="_blank"}.

First I removed the two steps Build solution _**/*test*.csproj_ and _Test_ because at the moment we don't use Xamarin Test Cloud,
we only run our tests while developing on the android emulator or direct on the device.
After that I created the three Variables which are needed for the Build process. On the _variables_ tab you have to add
these Variables:

* BuildConfiguration
   * Value is Release or another configuration you defined for your project
* xamarin.email
   * The email adress of your xamarin account
* xamarin.password
   * The password of your xamarin account
   * For the password you can click on the <i class="fa fa-lock"></i> icon to avoid exposing your password

To access a variable you have to write _$(VARIABLENAME)_.

![access-variables][access-variables]{:class="image-responsive"}

I tried to use mainly variables for the configuration. You can also embed a variable into another. For example I got a
variable called _Keystore.PathToFile_ with the value _$(Build.SourcesDirectory)\GuardianProject\Keystore\guardian.keystore_.

Now with the default build steps (without _Test_) and the needed variables we are ready for the next steps to configure
each step and add the missing ones.

## Step NuGet restore
At the _Advanced_ tab you can choose your NuGet version.

You can also provide a custom nuget.exe like i did. At the [NuGet download page][3]{:target="_blank"} you can get all 
versions of NuGet.

You just have to provide the path to the NuGet.config file and the path to the nuget.exe within your repository. So I created two variables

* NuGet.PathToExe: $(Build.SourcesDirectory)\NuGet\nuget.exe
* NuGet.PathToConfig: $(Build.SourcesDirectory)\NuGet.config

Now to use your custom version of nuget.exe you just have to:

* [download nuget.exe][3]{:target="_blank"}
* add it to your souce control
   * I created a folder _.nuget_ and placed the _nuget.exe_ and _NuGet.config_ here
* create variables including the path to the _nuget.exe_ and to the _NuGet.config_
* add these variables to your build step _NuGet restore_

This is the content of my _NuGet.config_ file

![nuget-variables][nuget-variables]{:class="image-responsive"}

{% highlight ruby %}
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" />
  </packageSources>
  <solution>
    <add key="disableSourceControlIntegration" value="true" />
  </solution>
</configuration>
{% endhighlight %}

The source is the official nuget source and _disableSourceControlIntegration_ just tells TFS not to include the restored
packages automatically in the source control.

## Xamarin component restore
We use one Xamarin component because there is no available NuGet package for this component (if so, please tell me). We use the
Dropbox Core API Android SDK component in our project, so we also have to restore components for our build. For this task you have to provide your email and your password for your xamarin account.
We already created two variables containing these informations and can use these variables with _$(xamarin.email)_
for the value of the required email textfield and _$(xamarin.password)_ for the value of the required password textfield.

And voila also Xamarin components are getting restored.

![xamarin-component-restore][xamarin-component-restore]{:class="image-responsive"}

## Build Xamarin.Android Project
This build step just searches for .csproj files with "Droid" in their name and compiles them. Here I just had to select the needed JDK Version. You can select the version in the _JDK Options_ tab.

## Signing and aligning APK file(s)
For manual signing the apk read the post [_Manual Signing the APK_][4]{:target="_blank"} on xamarin.com.

For signing you have to check _Sign the APK_ in the _Signing Options_ tab.
Now you have to provide the following information:

* Keystore File
* Keystore Password
* Alias
* Key Password

For each input field I used a variable:

* Keystore.PathToFile
* Keystore.Password
* Keystore.Alias
* Keystore.KeyPassword

For [aligning][5]{:target="_blank"} you have to check _Zipalign_ in the _Zipalign Options_.

![signing-and-aligning][signing-and-aligning]{:class="image-responsive"}

## Upload signed APK to database
For uploading the signed and aligned APK file to our database I used a PowerShell script.
So wee need a new build task to run a PowerShell script.

In the task tab you just have to click on _Add Task_, choose the tab _Utility_ and there is an item called _PowerShell_. You can also search for _PowerShell_ with the search box.

![new-powershell-task][new-powershell-task]{:class="image-responsive"}

Now you only have to provide the file path and the arguments for the PowerShell script.

![powershell-script][powershell-script]{:class="image-responsive"}

I created the following variables in the _Variables_ tab

* UploadApk.PathToScript
* UploadApk.VersionCode (checked _Settable at queue time_)
* UploadApk.VersionName (checked _Settable at queue time_)

and checked _Settable at queue time_ for the variables _UploadApk.VersionCode_ and _UploadApk.VersionName_. With this option you will be asked for the value of these variables, if you trigger a new build. So with each new version you can specify the new version code and the new version name.

[Here is the PowerShell script][6]{:target="_blank"} for uploading the apk to a database using an ASP.Net API.

Here is the code for ASP.Net API action for saving the apk file.

{% highlight ruby %}
// PUT api/apk/
[HttpPut]
public void Put(Apk apk, IFormFile apkFile)
{
    var apkToInsert = new Apk()
    {
        VersionCode = apk.VersionCode,
        VersionName = apk.VersionName,
        BuildName = apk.BuildName,
        ApkContent = apkFile.ToBytes()
    };

    DbContext.Apks.Add(apkToInsert);

    DbContext.SaveChanges();
}
{% endhighlight %}

## Publish Artifact
This task will just publish the created artifact (including all compiled files) and will save it at the succeeded build. You can access all these files after a successfull build.

![publish-artifact][publis-artifact]{:class="image-responsive"}

[1]: https://support.microsoft.com/de-de/kb/137503
[2]: https://www.visualstudio.com/docs/build/apps/mobile/xamarin
[3]: https://dist.nuget.org/index.html
[4]: https://developer.xamarin.com/guides/android/deployment,_testing,_and_metrics/publishing_an_application/part_2_-_signing_the_android_application_package/manually-signing-the-apk/
[5]: https://developer.android.com/studio/command-line/zipalign.html
[6]: {{ site.url }}/files/UpoadSignedApk.ps1

[create-a-build-definition]: {{ site.url }}/img/2016-09-20-use-build-definitions-with-microsoft-team-services-to-sign-and-upload-your-apk/create-a-build-definition.gif "Create a build definition"
[access-variables]: {{ site.url }}/img/2016-09-20-use-build-definitions-with-microsoft-team-services-to-sign-and-upload-your-apk/access-variables.png "Access variables"
[nuget-variables]: {{ site.url }}/img/2016-09-20-use-build-definitions-with-microsoft-team-services-to-sign-and-upload-your-apk/nuget-variables.png "NuGet variables"
[xamarin-component-restore]: {{ site.url }}/img/2016-09-20-use-build-definitions-with-microsoft-team-services-to-sign-and-upload-your-apk/xamarin-component-restore.png "Xamarin component restore"
[signing-and-aligning]: {{ site.url }}/img/2016-09-20-use-build-definitions-with-microsoft-team-services-to-sign-and-upload-your-apk/signing-and-aligning.png "Signing and aligning the APK"
[new-powershell-task]: {{ site.url }}/img/2016-09-20-use-build-definitions-with-microsoft-team-services-to-sign-and-upload-your-apk/new-powershell-task.gif "New PowerShell task"
[powershell-script]: {{ site.url }}/img/2016-09-20-use-build-definitions-with-microsoft-team-services-to-sign-and-upload-your-apk/powershell-script.png "PowerShell script"
[publish-artifact]: {{ site.url }}/img/2016-09-20-use-build-definitions-with-microsoft-team-services-to-sign-and-upload-your-apk/publish-artifact.png "Publish artifact"