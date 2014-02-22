
from flask import Flask
app = Flask(__name__)

app.debug = DEBUG


@app.route("/")
def hello():
    return "Hello World!"

@app.route("/compute/mp/<int:id>", method=["POST"])
def compute():
	return "Helloe"

if __name__ == "__main__":
    app.run()

