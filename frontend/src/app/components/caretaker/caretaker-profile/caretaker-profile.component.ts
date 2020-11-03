import { Component, OnInit } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { baseurl, getHttpOptionsWithAuth, httpOptions } from '../../../services/commons.service';
import { FormControl, FormGroup, FormBuilder, FormArray } from '@angular/forms';
import { AuthService } from 'src/app/services/auth/auth.service';
import { PetownerService } from 'src/app/services/petowner/petowner.service';
import { NONE_TYPE } from '@angular/compiler';
import { registerLocaleData } from '@angular/common';

@Component({
  selector: 'app-caretaker-profile',
  templateUrl: './caretaker-profile.component.html',
  styleUrls: ['./caretaker-profile.component.css']
})
export class CaretakerProfileComponent implements OnInit {

  userData = {caretaker: NONE_TYPE, petowner: NONE_TYPE};
  flatData;
  isCaretaker = false;
  isPetOwner = false;
  pets = [];
  petTypes;

  petArray = new FormArray([]);
  petForm: FormGroup;

  constructor(private http: HttpClient,
              private fb: FormBuilder,
              private authService: AuthService,
              private petOwnerService: PetownerService) {
                this.petForm = this.fb.group({
                  name:'',
                  petArrays: this.fb.array([]),
                })
              }

  profileForm = new FormGroup({
    name: new FormControl(''),
    password: new FormControl(''),
    description: new FormControl(''),
    case: new FormControl(''),
  });

  public getUser(): Observable<any> {
    return this.http.get(baseurl + '/api/auth/profile', getHttpOptionsWithAuth());
  }

  getOwnerPets() {
    this.petOwnerService.getPetOwnerPets().subscribe((pets) => {
       this.pets = pets;
       this.petArray = new FormArray([]);
       console.log(pets);
       this.populatePetArray();
    });
  }

  getUserData() {
    this.getUser().subscribe((user) => {
      
      this.flatData = user.flat()[0];      
      if (user[0][0] != undefined) {this.userData['caretaker'] = user[0][0]; this.isCaretaker = true;}
      if (user[1][0] != undefined) {this.userData['petowner'] = user[1][0]; this.isPetOwner = true;}
      console.log('isCaretaker:'+this.isCaretaker+', isPetOwner:'+this.isPetOwner);
      console.log(this.userData);
      this.profileForm.patchValue({
        name: [this.flatData.name],
        description: [this.flatData.description],
      })});
  }

  ngOnInit(): void {
    this.getUserData();
    this.getOwnerPets();
    console.log(this.isPetOwner);
  }

  populatePetArray() {
    for (const pet of this.pets) {
      console.log(pet);
      
      const group = this.fb.group({
      pet_name: pet.pet_name,
      special_requirements: pet.special_requirements,
      description: '',
      species: '',
      })

      this.petArrays.push(group);
    }
  }

  getListOfPetTypes() {
    this.petOwnerService.getListOfPetTypes().subscribe(petTypes => {
      this.petTypes = petTypes.map(elem => elem.species);
    });
  }

  // this.caretakerService.getCareTakerPrice(caretaker.email).subscribe((prices) => {
  //   prices;
  // });

  get petArrays(): FormArray {
    return this.petForm.get("petArrays") as FormArray;
  }

  newPet(): FormGroup {
    return this.fb.group({
      pet_name: '',
      special_requirements: '',
      description: '',
      species: '',
    })
  }

  addPets() {
    this.petArrays.push(this.newPet());
  }

  updatePet(i: number) {
    console.log(this.petArrays.at(i).value);
    console.log("Original pet: ");
    console.log(this.pets[i]);
  }

  removePet(i: number) {
    this.petArrays.removeAt(i);
  }

  onSubmit(profileParam): void {
    console.log('SENT');
    console.log(profileParam);
  }

  onSubmitPetArray() {
    console.log(this.petForm.value);
  }
}
