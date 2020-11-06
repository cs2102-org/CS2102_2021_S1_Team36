import { Component, OnInit } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { baseurl, getHttpOptionsWithAuth, httpOptions } from './../../../../services/commons.service';
import { FormControl, FormGroup, FormBuilder, FormArray, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import Base64 from 'crypto-js/enc-base64';
import Utf8 from 'crypto-js/enc-utf8'

@Component({
  selector: 'app-create-post',
  templateUrl: './create-post.component.html',
  styleUrls: ['./create-post.component.css']
})
export class CreatePostComponent implements OnInit {

  constructor(
    private http: HttpClient,
  ) { }

  newPostForm = new FormGroup({
    title: new FormControl(''),
    cont: new FormControl('')
  });
  
  onSubmit(details) {
    
    console.log(details);
    this.createPost(details).subscribe(x => {
      console.log(details);
    })
  }

  ngOnInit(): void {
  }

  createPost(details): Observable<any> {
    return this.http.post(baseurl + '/api/posts/create', details, getHttpOptionsWithAuth());
  }
}
