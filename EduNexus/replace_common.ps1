$path = "d:\NamBoDoi\Nam\CacMonHocKySummer2026\SWD392\Project\EduNexus\EduNexus\Views"
$files = Get-ChildItem -Path $path -Recurse -Filter *.cshtml

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $original = $content
    
    # Auth actions
    $content = [regex]::Replace($content, 'asp-controller="Common"(.*?)asp-action="(UserLogin|UserRegister|ForgotPassword|ResetPassword|SignOut|GoogleLogin|GoogleResponse)"', 'asp-controller="Auth"$1asp-action="$2"')
    $content = [regex]::Replace($content, 'asp-action="(UserLogin|UserRegister|ForgotPassword|ResetPassword|SignOut|GoogleLogin|GoogleResponse)"(.*?)asp-controller="Common"', 'asp-action="$1"$2asp-controller="Auth"')
    $content = [regex]::Replace($content, '"/Common/(UserLogin|UserRegister|ForgotPassword|ResetPassword|SignOut|GoogleLogin|GoogleResponse)(.*?)"', '"/Auth/$1$2"')
    $content = [regex]::Replace($content, '"Common", "(UserLogin|UserRegister|ForgotPassword|ResetPassword|SignOut|GoogleLogin|GoogleResponse)"', '"Auth", "$1"')
    $content = [regex]::Replace($content, '"(UserLogin|UserRegister|ForgotPassword|ResetPassword|SignOut|GoogleLogin|GoogleResponse)", "Common"', '"$1", "Auth"')
    
    # Student actions
    $content = [regex]::Replace($content, 'asp-controller="Common"(.*?)asp-action="(StudentDashboard|PersonalProgress|StudentSettings|UpdateProfile|ChangePassword|StudentLibrary)"', 'asp-controller="Student"$1asp-action="$2"')
    $content = [regex]::Replace($content, 'asp-action="(StudentDashboard|PersonalProgress|StudentSettings|UpdateProfile|ChangePassword|StudentLibrary)"(.*?)asp-controller="Common"', 'asp-action="$1"$2asp-controller="Student"')
    $content = [regex]::Replace($content, '"/Common/(StudentDashboard|PersonalProgress|StudentSettings|UpdateProfile|ChangePassword|StudentLibrary)(.*?)"', '"/Student/$1$2"')
    $content = [regex]::Replace($content, '"Common", "(StudentDashboard|PersonalProgress|StudentSettings|UpdateProfile|ChangePassword|StudentLibrary)"', '"Student", "$1"')
    $content = [regex]::Replace($content, '"(StudentDashboard|PersonalProgress|StudentSettings|UpdateProfile|ChangePassword|StudentLibrary)", "Common"', '"$1", "Student"')
    
    # CourseExplorer actions
    $content = [regex]::Replace($content, 'asp-controller="Common"(.*?)asp-action="(AllCourses|CourseList|CourseStructure)"', 'asp-controller="CourseExplorer"$1asp-action="$2"')
    $content = [regex]::Replace($content, 'asp-action="(AllCourses|CourseList|CourseStructure)"(.*?)asp-controller="Common"', 'asp-action="$1"$2asp-controller="CourseExplorer"')
    $content = [regex]::Replace($content, '"/Common/(AllCourses|CourseList|CourseStructure)(.*?)"', '"/CourseExplorer/$1$2"')
    $content = [regex]::Replace($content, '"Common", "(AllCourses|CourseList|CourseStructure)"', '"CourseExplorer", "$1"')
    $content = [regex]::Replace($content, '"(AllCourses|CourseList|CourseStructure)", "Common"', '"$1", "CourseExplorer"')

    if ($content -cne $original) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "Updated $($file.Name)"
    }
}
