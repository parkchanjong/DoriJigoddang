import React from "react";
import ReactDOM from "react-dom";
import "./index.css";
import App from "./App";
import CoinFlip from "./CoinFlip";
import registerServiceWorker from "./registerServiceWorker";

//ReactDOM.render(<App />, document.getElementById("root"));
ReactDOM.render(<CoinFlip />, document.getElementById("root"));
registerServiceWorker();
