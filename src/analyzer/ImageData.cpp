/**
 *  Project: AnalyzeHipGISAXS (High-Performance GISAXS Data Analysis)
 *
 *  File: ImageData.cpp
 *  Created: Dec 26, 2013
 *  Modified: Fri 31 Jan 2014 01:44:26 PM PST
 *
 *  Author: Slim Chourou <stchourou@lbl.gov>
 *  Developers: Slim Chourou <stchourou@lbl.gov>
 *              Abhinav Sarje <asarje@lbl.gov>
 *              Alexander Hexemer <ahexemer@lbl.gov>
 *              Xiaoye Li <xsli@lbl.gov>
 *
 *  Licensing: The AnalyzeHipGISAXS software is only available to be downloaded and
 *  used by employees of academic research institutions, not-for-profit
 *  research laboratories, or governmental research facilities. Please read the
 *  accompanying LICENSE file before downloading the software. By downloading
 *  the software, you are agreeing to be bound by the terms of this
 *  NON-COMMERCIAL END USER LICENSE AGREEMENT.
 */
#include <fstream>
#include <iostream>
#include <sstream>
#include <iterator>
#include <analyzer/ImageData.hpp>

namespace hig{

  float ImageData::img_p(int iv, int ip) const {
    if (ip < 0 || ip >= n_par_ || iv < 0 || iv >= n_ver_ )
      return 0;
    else{
      //return img_[iv][ip];
      return img_[iv * n_par_ + ip];
    }
  }

  float ImageData::img_q(float qv, float qp) const {
    return 0;
  }

  void  ImageData::print() const {
    std::cout << filename_ << std::endl;
    for(int iv=0; iv<n_ver_; iv++)
      {
	for(int ip=0; ip<n_par_; ip++)
	  {
	    std::cout << img_[iv * n_par_ + ip] << "  ";
	  }
	std::cout <<std::endl;
      }
  }

  void  ImageData::save(string_t filename) const {
    std::ofstream file;
    file.open (filename);

    for(int iv=0; iv<n_ver_; iv++)
      {
        for(int ip=0; ip<n_par_; ip++)
          {
	    file << img_[iv * n_par_ + ip] << "  ";
          }
	file << "\n";
      }
    file.close();
  }

  float_vec_t ImageData::read_string_values(string_t line){
    float_vec_t array;
    float val;

    std::stringstream ssin(line);
    std::copy(  std::istream_iterator<float>(ssin),
		std::istream_iterator<float>(),
		std::back_inserter(array));

    /*
    int c=0;
    while (ssin.good()){
      ssin >> val;
      array.push_back(val);
      std::cout <<c<< ":"  <<val << " - ";
      c++;
    }
    std::cout << std::endl;
    */

    return array;
  }

  void ImageData::read(string_t filename){
    img_.clear();
    int nv=-1;
    int np=0;
    string_t line;
    std::ifstream file(filename);
    if (file.is_open()) //if the file is open
      {
        while (!file.eof()) //while the end of file is NOT reached
	  {
	    getline(file,line); //get one line from the file
	    nv++;
	    float_vec_t img_z= read_string_values(line);
	    if(nv==0)
	      np= img_z.size();
	    img_.insert(img_.end(), img_z.begin(), img_z.end());
	  }
        file.close(); //closing the file
	n_par_ = np;
	n_ver_ = nv;
	convert_data();
      }
    else std::cout << "Unable to open file\n"; //if the file is not open output
  }


  // temporary .... -- abhinav
  float_t* ImageData::convert_data() {
	  std::cout << "ALLOCATING DATA MEMORY" << std::endl;
	  data_.clear();
	  unsigned int i = 0;
	  for(float_mat_t::iterator r = img_.begin(); r != img_.end(); ++ r) {
		  //for(float_vec_t::iterator c = (*r).begin(); c != (*r).end(); ++ c) {
			  data_.push_back(*r);
		  //} // for
	  } // for
  } // ImageData::data()

}
