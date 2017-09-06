You have 24 hours to deploy at least 2 instance of the Python application.  
You can:  
* Choose your favorite OS, provider and virtualization.
* Choose whatever tool or programming language you like to automate the process.

## PYTHON APP
The Python app is a simple API with two endpoints:  
* **/set**: accept a POST call to increase the value of the Redis key 'total'
* **/get**: accept a GET call to return the number of times you called the /set endpoint

You can set these environment variables:  
* ENV: set production or development environment. When in production mode, the app is only listening on localhost and debug mode is disabled  
* REDIS_HOST: Redis hostname  
