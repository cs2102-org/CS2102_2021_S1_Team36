import { Component, OnInit } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';

@Component({
  selector: 'app-create-post',
  templateUrl: './create-post.component.html',
  styleUrls: ['./create-post.component.css']
})
export class CreatePostComponent implements OnInit {

  constructor() { }

  newPostForm = new FormGroup({
    newPostTitle: new FormControl(''),
    newPostDesc: new FormControl('')
  });
  
  onSubmit() {}

  ngOnInit(): void {
  }

}
