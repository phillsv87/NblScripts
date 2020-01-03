#!/usr/local/bin/pwsh
param(
    [string]$projectDir,
    [string]$nugetKey=$null,
    [switch]$noPush,
    [switch]$noPack
)

$ErrorActionPreference = "Stop"

if(Test-Path -Path "~/.nugetkey"){
    Write-Host "Use key ~/.nugetkey"
    $nugetKey=(Get-Content "~/.nugetkey" -Raw).Trim()
}

if(!$nugetKey){
    Write-Host "Use key $env:NblKeyDir/nuget.key"
    $nugetKey=(Get-Content "$env:NblKeyDir/nuget.key" -Raw).Trim()
}

if(!$nugetKey){
    throw "nugetkey not specified. Either use the -nugetKey argument or set the NblKeyDir enviornment variable"
}

Push-Location $projectDir
try{
    [xml]$proj = Get-Content *.csproj
    $Version=$proj.Project.PropertyGroup.Version
    $PackageId=$proj.Project.PropertyGroup.PackageId

    if(!$Version){
        throw "Project.PropertyGroup.Version not set"
    }

    if(!$PackageId){
        throw "Project.PropertyGroup.PackageId not set"
    }

    Write-Host "Pack and Publish $PackageId-$Version"

    if(!$noPack){
        dotnet pack -c Release
        if( -not $?){
            throw "Pack $PackageId Failed"
        }
    }

    if(!$noPush){
        dotnet nuget push "bin/Release/$($PackageId).$($Version).nupkg" -k $nugetKey -s https://api.nuget.org/v3/index.json
        if( -not $?){
            throw "Publish $PackageId Failed"
        }
    }

    Write-Host "Publish $PackageId-$Version Success" -ForegroundColor DarkGreen

}finally{
    Pop-Location
}