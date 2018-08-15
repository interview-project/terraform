import jenkins.model.*

// Read the environment variable
url = "http://${jenkins_ip}"

// Get the config from our running instance
urlConfig = JenkinsLocationConfiguration.get()

// Set the config to be the value of the env var
urlConfig.setUrl(url)
urlConfig.setAdminAddress("Ken Erwin <ken@devopslibrary.com>");

// Save the configuration
urlConfig.save()

// Print the results
println("Jenkins URL Set to " + url)

