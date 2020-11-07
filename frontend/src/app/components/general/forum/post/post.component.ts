import { Component, OnInit } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { baseurl, getHttpOptionsWithAuth, httpOptions } from '../../../../services/commons.service';
import { FormControl, FormGroup, FormBuilder, FormArray, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import Base64 from 'crypto-js/enc-base64';
import Utf8 from 'crypto-js/enc-utf8'
import { AuthService } from 'src/app/services/auth/auth.service';

@Component({
  selector: 'app-post',
  templateUrl: './post.component.html',
  styleUrls: ['./post.component.css']
})
export class PostComponent implements OnInit {
  isLogged = false;

  constructor(
    private route: ActivatedRoute,
    private http: HttpClient,
    private authService: AuthService,
    private router: Router,
  ) { }

  flatData;
  showInput = false;
  Comments;
  Post = {
    'post_id': '',
    'title': '',
    'cont': '',
    'name': '',
    'email': '',
  };

  commentForm = new FormGroup({
    cont: new FormControl('')
  });



  goToBottom() {
    window.scrollTo(0, document.body.scrollHeight);
    this.showInput = true;
  }

  public getUser(): Observable<any> {
    return this.http.get(baseurl + '/api/auth/profile', getHttpOptionsWithAuth());
  }

  onSubmit(value) {
    value.post_id = this.Post.post_id;
    console.log(value);
    this.submitComment(value).subscribe(x => {
      console.log(x);
      this.populateComments();
      if (!x) {
        alert("Comment failed");
      } else {
        console.log("Comment Successful!");
        this.commentForm.reset()
      }
    })
  }

  delete(details) {
    console.log(details);
    this.deleteHttp(details).subscribe(x => {
      this.populateComments();
    });
  }

  deleteHttp(details) {
    return this.http.post(baseurl + '/api/comments/delete', details, getHttpOptionsWithAuth());
  }

  ngOnInit(): void {
    this.populateComments();
    this.checkIsLogged();
    if (this.isLogged) {
      this.getUser().subscribe(x => {
        this.flatData = x.flat()[0]
        console.log(this.flatData);
      })
    }
  }
  
  checkIsLogged() {
    this.isLogged = false;
    if (localStorage.getItem('accessToken') != null) {
      this.isLogged = true;
    }
    this.authService.loginNotiService
      .subscribe(message => {
        if (message == "Login success") {
          this.isLogged=true;
          this.getUser().subscribe(x => {
              this.flatData = x.flat()[0]
              console.log(this.flatData);
            })
        } else {
          this.isLogged=false;
        }
    });
    console.log(this.isLogged);
  }

  dateStringify(epoch) {
    return new Date(epoch * 1000).toUTCString();
  }

  submitComment(details) {
    return this.http.post(baseurl + '/api/comments/create', details, getHttpOptionsWithAuth());
  }

  getComments(postId): Observable<any> {
    const details = { 'post_id': postId }
    return this.http.post(baseurl + '/api/comments/', details, httpOptions);
  }

  getPost(postId): Observable<any> {
    const details = { 'post_id': postId }
    return this.http.post(baseurl + '/api/posts/specific', details, httpOptions);
  }

  populateComments() {
    var title = this.route.snapshot.paramMap.get("title");
    this.getComments(title).subscribe(x => {
      this.Comments = x;
    });
    this.getPost(title).subscribe(x => {
      this.Post = x[0];
      console.log(this.Post);
    })
  }

  edit(postId) {
    const url = this.router.serializeUrl(
      this.router.createUrlTree(['/edit-post/'+postId])
    );
    window.open(url, "_self");
  }

}
