import { Component, OnInit } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { baseurl, getHttpOptionsWithAuth, httpOptions } from '../../../services/commons.service';
import { FormControl, FormGroup, FormBuilder, FormArray, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import Base64 from 'crypto-js/enc-base64';
import Utf8 from 'crypto-js/enc-utf8'

@Component({
  selector: 'app-forum',
  templateUrl: './forum.component.html',
  styleUrls: ['./forum.component.css']
})
export class ForumComponent implements OnInit {

  constructor(
    private http: HttpClient,
    private router: Router,
  ) { }

  posts;
  flatData;
  isPcsAdmin;


  ngOnInit(): void {
    this.populatePosts();
    this.getFlatData();
  }

  public getUser(): Observable<any> {
    return this.http.get(baseurl + '/api/auth/profile', getHttpOptionsWithAuth());
  }

  getFlatData() {
    this.getUser().subscribe((user) => {
      this.flatData = user.flat()[0];
      if (user[2][0] != undefined) {this.isPcsAdmin = true; }
    });
  }

  getAllPosts(): Observable<any> {
    return this.http.get(baseurl + '/api/posts/', httpOptions);
  }

  populatePosts() {
    this.getAllPosts().subscribe(x => {
      this.posts = x;
      console.log(x);
    })
  }

  openPost(selectedPostId) {
    const url = this.router.serializeUrl(
      this.router.createUrlTree(['/post/' + selectedPostId])
    );
    window.open(url, "_self");
  }

  addPost() {
    const url = this.router.serializeUrl(
      this.router.createUrlTree(['/create-post/'])
    );
    window.open(url, "_self");
  }

  delete(details) {
    console.log(details);
    this.deleteHttp(details).subscribe(x => {
      this.populatePosts();
    });
  }

  deleteHttp(details) {
    return this.http.post(baseurl + '/api/posts/delete/' + details.post_id, details, getHttpOptionsWithAuth());
  }


}
