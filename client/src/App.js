import React, { Component } from "react";
import "./App.css";
import logo from "./logo.svg";

class App extends Component {
  render() {
    return (
      <div className="App">
        <header>
          <img src={logo} className="App-logo" alt="logo" />
          <h1 className="App-font">동전 앞 뒤 맞추기!</h1>
        </header>
      </div>
    );
  }
}

export default App;
