import React from "react";
import axios from "../customAxiosConfig/CustomAxiosConfig";

const HomeService = () => {
  try {
    return axios.get("/");
  } catch (err) {
    let error = "";
    if (err.response) {
      error += err.response;
    }
    return error;
  }
};

export default HomeService;
