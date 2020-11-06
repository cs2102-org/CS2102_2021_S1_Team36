import { Component, OnInit } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { baseurl, getHttpOptionsWithAuth, httpOptions } from './../../../../services/commons.service';
import { FormControl, FormGroup, FormBuilder, FormArray, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';

@Component({
  selector: 'app-edit-post',
  templateUrl: './edit-post.component.html',
  styleUrls: ['./edit-post.component.css']
})
export class EditPostComponent implements OnInit {

  constructor(
    private http: HttpClient,
    private route: ActivatedRoute,
  ) { }

  editPostForm = new FormGroup({
    title: new FormControl(''),
    cont: new FormControl('')
  });;

  onSubmit(details) {
    console.log(details);
    this.editPost(details).subscribe(x => {
      console.log(details);
    })
  }

  ngOnInit(): void {
    this.getPost().subscribe(x => {
      console.log(x);
      this.editPostForm.patchValue({
        title: x[0].title,
        cont: x[0].cont,
      })
    });
  }

  getPost(): Observable<any> {
    var title = this.route.snapshot.paramMap.get("title");
    const details = { 'post_id': title }
    return this.http.post(baseurl + '/api/posts/specific', details, httpOptions);
  }

  editPost(details): Observable<any> {
    var title = this.route.snapshot.paramMap.get("title");
    return this.http.put(baseurl + '/api/posts/' + title, details, getHttpOptionsWithAuth());
  }

}
